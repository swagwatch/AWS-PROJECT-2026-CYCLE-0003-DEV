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
  description = "Certificate validation method. Valid values: DNS or EMAIL. DNS is recommended."
  type        = string
  default     = "DNS"

  validation {
    condition     = contains(["DNS", "EMAIL"], var.validation_method)
    error_message = "Validation method must be either DNS or EMAIL."
  }
}

variable "tags" {
  description = "A map of tags to assign to the certificate"
  type        = map(string)
  default     = {}
}

variable "certificate_transparency_logging_preference" {
  description = "Certificate transparency logging preference. Valid values: ENABLED or DISABLED."
  type        = string
  default     = "ENABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.certificate_transparency_logging_preference)
    error_message = "Certificate transparency logging preference must be either ENABLED or DISABLED."
  }
}

variable "key_algorithm" {
  description = "Algorithm for the certificate's private key. Valid values: RSA_2048, RSA_4096, EC_prime256v1, EC_secp384r1"
  type        = string
  default     = "RSA_2048"

  validation {
    condition     = contains(["RSA_2048", "RSA_4096", "EC_prime256v1", "EC_secp384r1"], var.key_algorithm)
    error_message = "Key algorithm must be one of: RSA_2048, RSA_4096, EC_prime256v1, EC_secp384r1."
  }
}
