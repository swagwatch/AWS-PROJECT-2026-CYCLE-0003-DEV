output "certificate_arn" {
  description = "The ARN of the certificate"
  value       = module.certificatemanager_cert.certificate_arn
}

output "certificate_id" {
  description = "The ARN of the certificate (same as arn)"
  value       = module.certificatemanager_cert.certificate_id
}

output "certificate_domain_name" {
  description = "The domain name for which the certificate is issued"
  value       = module.certificatemanager_cert.certificate_domain_name
}

output "certificate_status" {
  description = "The status of the certificate"
  value       = module.certificatemanager_cert.certificate_status
}

output "domain_validation_options" {
  description = "A list of attributes to feed into other resources to complete certificate validation"
  value       = module.certificatemanager_cert.domain_validation_options
}

output "certificate_not_after" {
  description = "The expiration date and time for the certificate"
  value       = module.certificatemanager_cert.certificate_not_after
}

output "certificate_not_before" {
  description = "The start of the validity period of the certificate"
  value       = module.certificatemanager_cert.certificate_not_before
}
