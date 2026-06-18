variable "domain_name" {
  description = "Primary domain name for the certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names to include in the certificate"
  type        = list(string)
  default     = []
}

variable "validation_method" {
  description = "Certificate validation method. Valid values: DNS or EMAIL"
  type        = string
  default     = "DNS"
}

variable "key_algorithm" {
  description = "Algorithm for the certificate's private key"
  type        = string
  default     = "RSA_2048"
}

variable "certificate_transparency_logging_preference" {
  description = "Certificate transparency logging preference"
  type        = string
  default     = "ENABLED"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner team or individual responsible for the certificate"
  type        = string
}

variable "project" {
  description = "Project name for the certificate"
  type        = string
}
