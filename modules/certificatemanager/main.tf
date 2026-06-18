# AWS Certificate Manager (ACM) Certificate
resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = var.validation_method

  # Certificate options
  options {
    certificate_transparency_logging_preference = var.certificate_transparency_logging_preference
  }

  # Key algorithm for the certificate
  key_algorithm = var.key_algorithm

  # Tags
  tags = local.tags

  # Lifecycle configuration
  lifecycle {
    create_before_destroy = true
  }
}
