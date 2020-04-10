module "naming" {
  source      = "git::https://github.com/MagnetarIT/terraform-naming-standard.git?ref=tags/0.1.0"
  namespace   = var.namespace
  environment = var.environment
  name        = var.name
  attributes  = var.attributes
  tags        = var.tags
}

data "aws_region" "current" {
}

resource "aws_s3_bucket" "default" {
  bucket        = module.naming.id
  acl           = var.acl
  region        = var.region == "" ? data.aws_region.current.name : var.region
  force_destroy = var.force_destroy
  policy        = var.policy

  versioning {
    enabled = var.versioning_enabled
  }

  lifecycle_rule {
    id      = module.naming.id
    enabled = var.lifecycle_rule_enabled

    prefix = var.lifecycle_prefix
    tags   = var.lifecycle_tags

    noncurrent_version_expiration {
      days = var.noncurrent_version_expiration_days
    }

    dynamic "noncurrent_version_transition" {
      for_each = var.enable_glacier_transition ? [1] : []

      content {
        days          = var.noncurrent_version_transition_days
        storage_class = "GLACIER"
      }
    }

    transition {
      days          = var.standard_transition_days
      storage_class = "STANDARD_IA"
    }

    dynamic "transition" {
      for_each = var.enable_glacier_transition ? [1] : []

      content {
        days          = var.glacier_transition_days
        storage_class = "GLACIER"
      }
    }

    expiration {
      days = var.expiration_days
    }
  }

  # https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html
  # https://www.terraform.io/docs/providers/aws/r/s3_bucket.html#enable-default-server-side-encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = var.kms_master_key_arn
      }
    }
  }

  tags = module.naming.tags
}

# Refer to the terraform documentation on s3_bucket_public_access_block at
# https://www.terraform.io/docs/providers/aws/r/s3_bucket_public_access_block.html
# for the nuances of the blocking options
resource "aws_s3_bucket_public_access_block" "default" {
  bucket = join("", aws_s3_bucket.default.*.id)

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}