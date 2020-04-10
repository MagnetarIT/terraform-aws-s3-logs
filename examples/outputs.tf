output "bucket_domain_name" {
  value       = module.s3.bucket_domain_name
  description = "FQDN of bucket"
}

output "bucket_id" {
  value       = module.s3.bucket_id
  description = "Bucket Name (aka ID)"
}

output "bucket_arn" {
  value       = module.s3.bucket_arn
  description = "Bucket ARN"
}

output "prefix" {
  value       = module.s3.prefix
  description = "Prefix configured for lifecycle rules"
}
