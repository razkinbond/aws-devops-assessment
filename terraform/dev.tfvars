aws_region          = "ap-south-2"
environment         = "dev"
vpc_cidr            = "10.0.0.0/16"

# Database Settings
db_name             = "appdb_dev"
db_username         = "dbadmin_dev"
db_instance_class   = "db.t3.micro"

# ECS Application Settings
ecs_desired_count   = 1
container_cpu       = "256" # 0.25 vCPU
container_memory    = "512" # 512 MB

# Monitoring & Alerting
alert_enabled       = true
alert_email         = ""