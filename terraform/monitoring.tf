resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.environment}-frontend"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.environment}-backend"
  retention_in_days = 30
}

resource "aws_sns_topic" "alerts" {
  count = var.alert_enabled ? 1 : 0
  name  = "${var.environment}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_enabled && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {
  count                     = var.alert_enabled ? 1 : 0
  alarm_name                = "${var.environment}-alb-target-5xx"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 2
  metric_name               = "HTTPCode_Target_5XX_Count"
  namespace                 = "AWS/ApplicationELB"
  period                    = 300
  statistic                 = "Sum"
  threshold                 = 5
  alarm_description         = "Alert when the application load balancer target returns 5xx responses"
  alarm_actions             = [aws_sns_topic.alerts[0].arn]
  ok_actions                = [aws_sns_topic.alerts[0].arn]
  insufficient_data_actions = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "frontend_cpu_high" {
  count                     = var.alert_enabled ? 1 : 0
  alarm_name                = "${var.environment}-frontend-cpu-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 80
  alarm_description         = "Alert when frontend ECS service CPU exceeds 80%"
  alarm_actions             = [aws_sns_topic.alerts[0].arn]
  ok_actions                = [aws_sns_topic.alerts[0].arn]
  insufficient_data_actions = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.frontend.name
  }
}

resource "aws_cloudwatch_metric_alarm" "backend_cpu_high" {
  count                     = var.alert_enabled ? 1 : 0
  alarm_name                = "${var.environment}-backend-cpu-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 80
  alarm_description         = "Alert when backend ECS service CPU exceeds 80%"
  alarm_actions             = [aws_sns_topic.alerts[0].arn]
  ok_actions                = [aws_sns_topic.alerts[0].arn]
  insufficient_data_actions = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.backend.name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  count                     = var.alert_enabled ? 1 : 0
  alarm_name                = "${var.environment}-rds-low-storage"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = 2
  metric_name               = "FreeStorageSpace"
  namespace                 = "AWS/RDS"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 2000000000
  alarm_description         = "Alert when RDS storage space is running low"
  alarm_actions             = [aws_sns_topic.alerts[0].arn]
  ok_actions                = [aws_sns_topic.alerts[0].arn]
  insufficient_data_actions = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.identifier
  }
}
