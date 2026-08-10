# 1. Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name              = "${var.environment}-alb-sg"
  description       = "Allow public HTTP traffic to ALB"
  vpc_id            = aws_vpc.main.id

  depends_on        = [aws_vpc.main]

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-alb-sg" }
}

# 2. Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  depends_on = [aws_internet_gateway.gw, aws_subnet.public_1, aws_subnet.public_2, aws_security_group.alb_sg]

  tags = { Name = "${var.environment}-alb" }
}

# 3. Target Groups
resource "aws_lb_target_group" "frontend_tg" {
  name        = "${var.environment}-frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  depends_on = [aws_vpc.main]

  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = { Name = "${var.environment}-frontend-tg" }
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "${var.environment}-backend-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  depends_on = [aws_vpc.main]

  health_check {
    path                = "/health"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = { Name = "${var.environment}-backend-tg" }
}

# 4. Listeners & Rules
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  depends_on = [aws_lb.main, aws_lb_target_group.frontend_tg]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  depends_on = [aws_lb_listener.http, aws_lb_target_group.backend_tg]

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/health", "/docs"]
    }
  }
}
