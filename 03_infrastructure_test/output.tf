###########
# Outputs #
###########

output "backup_lambda_arn" {
  value = aws_lambda_function.rds_backup.arn
}

output "backup_lambda_name" {
  value = aws_lambda_function.rds_backup.function_name
}

output "copy_lambda_arn" {
  value = aws_lambda_function.rds_copy.arn
}

output "copy_lambda_name" {
  value = aws_lambda_function.rds_copy.function_name
}

