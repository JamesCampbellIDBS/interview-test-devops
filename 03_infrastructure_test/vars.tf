variable "env" {
  type        = string
  description = "one of dev, prod"
}

variable "aws_region" {
  type        = string
  description = "The AWS region to deploy resources to"
}

variable "aws_role_arn" {
  type        = string
  description = "The AWS Role ARN to assume"
}

variable "resource_owner" {
  type        = string
  description = "Used for tagging resources. Typically the Dept, or Customer name"
}

variable "permissions_boundary" {
  description = "Permission boundary to use for iam creation"
  type        = string
}

variable "lambda_timeout" {
  type        = number
  description = "The Lambda execution timeout value(s)"
  default     = 60
}

variable "lambda_memory_size" {
  type        = number
  description = "The memory(MB) allocation of the Lambda"
  default     = 5120
}

variable "backup_schedule" {
  type        = string
  description = "The cron expression to run the backup lambda on"
}

variable "copy_schedule" {
  type        = string
  description = "The cron expression to run the copy backup lambda on"
}

variable "schedule_enabled" {
  type        = string
  description = "Boolean. If true, the lambda is triggered according to `schedule`. Defaults to true."
  default     = true
}

variable "database_prefix" {
  type        = string
  description = "The prefix of the database names to backup. E.g. sreprodbd. Where a full name might be sreprod<customer>"
  default     = "sreprod"
}