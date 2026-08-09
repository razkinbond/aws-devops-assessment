output "vpc_id" {
  value = aws_vpc.main.id
}

output "rds_endpoint" {
  value     = aws_db_instance.postgres.endpoint
  sensitive = true
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_secret.arn
}

output "alb_dns_name" {
  description = "Public URL of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "ecr_frontend_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "ecr_backend_url" {
  value = aws_ecr_repository.backend.repository_url
}