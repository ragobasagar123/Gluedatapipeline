terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# ---------------------
# S3 buckets
# ---------------------

resource "aws_s3_bucket" "source_bucket" {
  bucket = "etl-source-bucket-sagarr"
tags={
Name = "Source Bucket"
}
}
resource "aws_s3_bucket_public_access_block" "source_bucket_block" {
  bucket                  = aws_s3_bucket.source_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "destination_bucket" {
  bucket = "etl-destination-bucket-sagarr"
tags={
Name = "Destination Bucket"
}
}

resource "aws_s3_bucket_public_access_block" "destination_bucket_block" {
  bucket                  = aws_s3_bucket.destination_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# ---------------------
# Glue IAM role
# ---------------------

resource "aws_iam_role" "glue_role" {
  name = "glue-etl-role-assignment"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
tags={
Name = "Glue Role"
}
}
resource "aws_iam_role_policy" "glue_policy" {
  name = "glue-s3-policy"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.source_bucket.arn,
          "${aws_s3_bucket.source_bucket.arn}/*",
          aws_s3_bucket.destination_bucket.arn,
          "${aws_s3_bucket.destination_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# ---------------------
# Glue job
# ---------------------

resource "aws_glue_job" "etl_job" {
  name     = "etl_transform_job"
  role_arn = aws_iam_role.glue_role.arn

  glue_version      = "3.0"
  worker_type       = "G.1X"
  number_of_workers = 2

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.source_bucket.bucket}/scripts/transform.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language" = "python"
    "--TempDir"      = "s3://${aws_s3_bucket.source_bucket.bucket}/temp/"
  }
}

