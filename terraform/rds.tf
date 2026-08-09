# Security Group for Database
resource "aws_security_group" "rds_sg" {
  name        = "${var.environment}-rds-sg"
  description = "Allow inbound database connections from App layer"
  vpc_id      = aws_vpc.main.id
  
  depends_on  = [aws_vpc.main, aws_subnet.private_app_1, aws_subnet.private_app_2]

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private_app_1.cidr_block, aws_subnet.private_app_2.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-rds-sg" }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = [aws_subnet.private_db_1.id, aws_subnet.private_db_2.id]
  
  depends_on = [aws_subnet.private_db_1, aws_subnet.private_db_2]
  tags = { Name = "${var.environment}-db-subnet-group" }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier             = "${var.environment}-postgres-db"
  allocated_storage      = 20
  max_allocated_storage  = 50
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false

  # Critical dependency: RDS needs Subnet Group, SG, and Passwords created first
  depends_on = [
    aws_db_subnet_group.rds_subnet_group,
    aws_security_group.rds_sg,
    random_password.db_password
  ]

  tags = { Name = "${var.environment}-postgres-db" }
}