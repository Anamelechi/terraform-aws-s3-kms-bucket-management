output "bucket_names" {
  value = [for b in aws_s3_bucket.this : b.bucket]
}

output "bucket_arns" {
  value = [for b in aws_s3_bucket.this : b.arn]
}

output "kms_key_arn" {
  value = try(aws_kms_key.s3_kms[0].arn, null)
}