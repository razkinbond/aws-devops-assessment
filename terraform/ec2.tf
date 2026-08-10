# Automatically query the latest Amazon Linux 2023 AMI for your region
data "aws_ssm_parameter" "al2023_ami" {
  name              = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# 1. Security Group for EC2 App Instances
resource "aws_security_group" "ec2_sg" {
  name              = "${var.environment}-ec2-sg"
  description       = "Allow traffic from ALB"
  vpc_id            = aws_vpc.main.id

  # Explicitly wait for VPC and ALB Security Group to exist
  depends_on = [
    aws_vpc.main,
    aws_security_group.alb_sg
  ]

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-ec2-sg" }
}

# 2. IAM Role for EC2 Systems Manager (SSM)
resource "aws_iam_role" "ec2_role" {
  name               = "${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version          = "2012-10-17"
    Statement        = [{
      Action         = "sts:AssumeRole"
      Effect         = "Allow"
      Principal      = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# 3. Attach SSM Managed Policy to IAM Role
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role               = aws_iam_role.ec2_role.name
  policy_arn         = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  depends_on = [aws_iam_role.ec2_role]
}

# 4. Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name               = "${var.environment}-ec2-instance-profile"
  role               = aws_iam_role.ec2_role.name

  # Must wait for policy attachment to finish so EC2 boots with SSM enabled
  depends_on = [aws_iam_role_policy_attachment.ec2_ssm_policy]
}

# 5. Launch Template for Non-Containerized App Server
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-app-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  # Ensure Security Group and IAM Profile are fully provisioned first
  depends_on = [
    aws_security_group.ec2_sg,
    aws_iam_instance_profile.ec2_profile
  ]

  # UserData script to pre-install Node.js and Python on EC2
  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo dnf update -y
              sudo dnf install -y nodejs python3 python3-pip git
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.environment}-app-ec2" }
  }
}

# 6. Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name                = "${var.environment}-app-asg"
  vpc_zone_identifier = [aws_subnet.private_app_1.id, aws_subnet.private_app_2.id]
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Critical dependency: ASG launching instances into private subnets needs 
  # the NAT Gateway and route tables fully attached first to allow outbound internet for UserData script!
  depends_on = [
    aws_launch_template.app,
    aws_nat_gateway.nat,
    aws_route_table_association.priv_app_1,
    aws_route_table_association.priv_app_2
  ]
}