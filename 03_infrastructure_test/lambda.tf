terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.73.0"
    }
  }
}

data "aws_caller_identity" "this" {}

# Setting locals, for consistent naming & avoiding duplication
locals {
  backup_resource_name = "rds-backup-${var.env}-${terraform.workspace}"
  copy_resource_name = "rds-copy-${var.env}-${terraform.workspace}"
  aws_acc_id            = data.aws_caller_identity.this.account_id
  tags = {
    resource_owner = var.resource_owner
    created_by     = "Terraform"
    Environment    = var.env
    Application    = terraform.workspace
  }
}

provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = var.aws_role_arn
  }
  default_tags = {
    tags = local.tags
  }
}

resource "aws_lambda_function" "rds_backup" {
  filename         = data.archive_file.rds_backup_zip.output_path
  source_code_hash = data.archive_file.rds_backup_zip.output_base64sha256
  function_name    = "${local.backup_resource_name}-lambda"
  handler          = "rds_backup.lambda_handler"
  role             = aws_iam_role.rds_backup_role.arn
  runtime          = "python3.8"
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  environment {
    variables = {
      SNS_ARN = aws_sns_topic.rds-backup-sns.arn
      DB_PREFIX = var.database_prefix
    }
  }
}

resource "aws_lambda_function" "rds_copy" {
  filename         = data.archive_file.rds_backup_zip.output_path
  source_code_hash = data.archive_file.rds_backup_zip.output_base64sha256
  function_name    = "${local.copy_resource_name}-lambda"
  handler          = "rds_backup.lambda_handler"
  role             = aws_iam_role.rds_copy_role.arn
  runtime          = "python3.8"
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  environment {
    variables = {
      SNS_ARN   = aws_sns_topic.rds-copy-sns.arn
      DB_PREFIX = var.database_prefix
    }
  }
}

data "archive_file" "rds_backup_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_functions/rds_backup/"
  output_path = "${path.module}/rds_backup.zip"
}

data "archive_file" "rds_copy_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_functions/rds_copy/"
  output_path = "${path.module}/rds_copy.zip"
}


resource "aws_sns_topic" "rds-backup-sns" {
  name = "${local.backup_resource_name}-topic"
}

resource "aws_sns_topic" "rds-copy-sns" {
  name = "${local.copy_resource_name}-topic"
}

### triggers
resource "aws_cloudwatch_event_rule" "backup_lambda_trigger" {
  name                = "${local.backup_resource_name}_lambda_trigger"
  description         = "Trigger the ${local.backup_resource_name} function for ${var.env}"
  schedule_expression = var.backup_schedule
  is_enabled          = var.schedule_enabled
}

resource "aws_cloudwatch_event_target" "backup_lambda_target" {
  rule = aws_cloudwatch_event_rule.backup_lambda_trigger.name
  arn  = aws_lambda_function.rds_backup.function_name
}

### triggers
resource "aws_cloudwatch_event_rule" "copy_lambda_trigger" {
  name                = "${local.copy_resource_name}_lambda_trigger"
  description         = "Trigger the ${local.copy_resource_name} function for ${var.env}"
  schedule_expression = var.backup_schedule
  is_enabled          = var.schedule_enabled
}

resource "aws_cloudwatch_event_target" "backup_lambda_target" {
  rule = aws_cloudwatch_event_rule.copy_lambda_trigger.name
  arn  = aws_lambda_function.rds_backup.function_name
}

### Alarms
resource "aws_cloudwatch_metric_alarm" "alert_on_backup_invocation_error" {
  alarm_name          = "${local.backup_resource_name}-alert_on_invocation_error"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Alert if the Lambda fails to run"
  treat_missing_data  = "ignore"
  alarm_actions       = [aws_sns_topic.rds-backup-sns.arn]

  dimensions = {
    FunctionName = aws_lambda_function.rds_backup.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "alert_on_invocation_error" {
  alarm_name          = "${local.copy_resource_name}-alert_on_invocation_error"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Alert if the Lambda fails to run"
  treat_missing_data  = "ignore"
  alarm_actions       = [aws_sns_topic.rds-copy-sns.arn]

  dimensions = {
    FunctionName = aws_lambda_function.rds_copy.function_name
  }
}
