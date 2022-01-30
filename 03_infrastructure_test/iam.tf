
resource "aws_iam_role" "rds_backup_role" {
  permissions_boundary = var.permissions_boundary
  name = "rds-backup-${local.general_resource_name}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "AllowLambdaToExecute"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "rds_backup_permissions" {
  name = "rds-backup-${local.general_resource_name}-permissions"
  role = aws_iam_role.rds_backup_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowFunctionToLogOutput",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*"
    },
    {
  "Sid": "AllowFunctionToCreateSnapshots",
  "Effect": "Allow",
  "Action": [
    "rds:DescribeDBInstances",
    "rds:DescribeDBClusterSnapshotAttributes",
    "rds:ListTagsForResource",
    "rds:DescribeDBSnapshots",
    "rds:CreateDBSnapshot",
    "rds:CreateDBClusterSnapshot",
    "rds:DescribeDBSnapshotAttributes",
    "ec2:DescribeRegions",
    "kms:Encrypt",
    "kms:Decrypt",
    "kms:ReEncrypt*",
    "kms:GenerateDataKey*",
    "kms:DescribeKey",
    "kms:CreateGrant",
    "kms:RetireGrant",
  ],
  "Resource": "*"
},
{
  "Sid": "AllowFunctionToSendSNS",
  "Effect": "Allow",
  "Action": [
    "sns:Publish"
  ],
  "Resource": "${aws_sns_topic.rds-backup-sns.arn}"
}
  ]
}
EOF
}


resource "aws_iam_role" "rds_copy_role" {
  permissions_boundary = var.permissions_boundary
  name = "rds-copy-${local.general_resource_name}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "AllowLambdaToExecute"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "rds_copy_permissions" {
  name = "rds-copy-${local.general_resource_name}-permissions"
  role = aws_iam_role.rds_copy_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowFunctionToLogOutput",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowFunctionToCopySnapshots",
      "Effect": "Allow",
      "Action": [
        "rds:DescribeDBInstances",
        "rds:DescribeDBClusterSnapshotAttributes",
        "rds:ListTagsForResource",
        "rds:DescribeDBSnapshots",
        "rds:ModifyDBSnapshotAttribute",
        "rds:CopyDBSnapshot",
        "rds:CopyDBClusterSnapshot",
        "rds:ModifyDBInstance",
        "rds:DescribeDBSnapshotAttributes",
        "ec2:DescribeRegions",
        "sts:AssumeRole",
        "sns:Publish"
      ],
      "Resource": "${aws_sns_topic.rds-copy-sns.arn}"
    },
  {
    "Sid": "AllowFunctionToSendSNS",
    "Effect": "Allow",
    "Action": [
      "sns:Publish"
    ],
    "Resource": "*"
  }
  ]
}
EOF
}
