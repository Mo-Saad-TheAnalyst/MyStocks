provider "aws" {
  region = "us-east-1"
  version = "4.61.0"
}

variable "stream_name" {
  type        = string
  description = "Name of the Kinesis Data Stream"
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket to store data"
}

resource "random_pet" "bucket_suffix" {
  length = 4
}

resource "aws_kinesis_stream" "kinesis_stream" {
  name             = var.stream_name
  shard_count      = 1
  retention_period = 24
}

resource "aws_s3_bucket" "s3bucket" {
  bucket = "${var.s3_bucket_name}-${random_pet.bucket_suffix.id}"
}

resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name        = "StocksFirehose"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.kinesis_stream.arn
    role_arn           = aws_iam_role.firehose_delivery_role.arn
  }

  extended_s3_configuration {
    role_arn = aws_iam_role.firehose_delivery_role.arn
    bucket_arn = aws_s3_bucket.s3bucket.arn
    dynamic_partitioning_configuration {
      enabled = "true"
    }

    prefix     = "!{partitionKeyFromQuery:type}/!{partitionKeyFromQuery:stock_name}/"
    error_output_prefix = "errors/"
    buffer_size = 64
    buffer_interval = 60
    compression_format = "UNCOMPRESSED"

    processing_configuration {
      enabled = "true"

      # New line delimiter processor example
      processors {
        type = "AppendDelimiterToRecord"
      }

      # JQ processor example
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{stock_name:.stock_name,type:.type}"
        }
      }
  }
}

  depends_on = [
    aws_kinesis_stream.kinesis_stream,
    aws_s3_bucket.s3bucket
  ]
}

resource "aws_iam_role" "firehose_delivery_role" {
  name = "firehose-delivery-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_s3_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.firehose_delivery_role.name
}

resource "aws_iam_role_policy_attachment" "firehose_kinesis_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
  role       = aws_iam_role.firehose_delivery_role.name
}

