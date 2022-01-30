# backend config to store terraform state & lock. Assumes the existence of both the S3 bucket, and DynamoDB table.

bucket                = "prod-terraform-state"
region                = "eu-west-1"
dynamodb_table        = "prod-terraform-state-lock"
role_arn              = "arn:aws:iam::<AWS-ACC-ID>:role/prod-terraform-state-access"
workspace_key_prefix  = "sre/rds-backup/envs:"
key                   = "terraform.state"