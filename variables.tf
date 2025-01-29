variable "bucket_base_names" {
  description = "Base names for S3 buckets (will have random suffixes)"
  type        = list(string)
  default     = ["s3bucket-1", "s3bucket-2"]
}

variable "enable_versioning" {
  description = "Enable versioning for all buckets"
  type        = bool
  default     = true
}

variable "kms_key_config" {
  description = "Configuration for KMS key"
  type = object({
    description             = string
    deletion_window_in_days = number
    enable_key_rotation     = bool
  })
  default = {
    description             = "S3 bucket encryption key"
    deletion_window_in_days = 7
    enable_key_rotation     = true
  }
}

variable "sse_configuration" {
  description = "Server-side encryption configuration"
  type = object({
    enabled     = bool
    algorithm   = string
    kms_key_arn = string
  })
  default = {
    enabled     = true
    algorithm   = "aws:kms"
    kms_key_arn = null
  }
}

variable "iam_role_name" {
  description = "Name for IAM role"
  type        = string
  default     = "s3-kms-role"
}