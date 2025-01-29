# Create KMS key if encryption is enabled and no existing key is provided
resource "aws_kms_key" "s3_kms" {
  count = var.sse_configuration.enabled && var.sse_configuration.kms_key_arn == null ? 1 : 0

  description             = var.kms_key_config.description
  deletion_window_in_days = var.kms_key_config.deletion_window_in_days
  enable_key_rotation     = var.kms_key_config.enable_key_rotation
}

# Create S3 buckets
# Generate a single random suffix for all buckets
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Create S3 buckets with random suffixes
resource "aws_s3_bucket" "this" {
  for_each = toset(var.bucket_base_names) # Use static base names here

  bucket = "${each.key}-${random_id.bucket_suffix.hex}" # Suffix added here
  force_destroy = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Configure server-side encryption for each bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_configuration.algorithm
      kms_master_key_id = coalesce(
        var.sse_configuration.kms_key_arn,
        try(aws_kms_key.s3_kms[0].arn, null)
      )
    }
  }
}

# IAM Role and Policy
resource "aws_iam_role" "this" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "s3_kms" {
  name = "s3-kms-access-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
        Effect   = "Allow",
        Resource = [for b in aws_s3_bucket.this : "${b.arn}/*"]
      },
      {
        Action   = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey"],
        Effect   = "Allow",
        Resource = var.sse_configuration.enabled ? [
          coalesce(
            var.sse_configuration.kms_key_arn,
            try(aws_kms_key.s3_kms[0].arn, null)
          )
        ] : []
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.s3_kms.arn
}
