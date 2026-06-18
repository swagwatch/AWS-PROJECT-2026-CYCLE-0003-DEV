# AWS Certificate Manager module instantiation for dev environment
module "certificatemanager_cert" {
  source = "../../modules/certificatemanager"

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = var.validation_method
  key_algorithm             = var.key_algorithm

  certificate_transparency_logging_preference = var.certificate_transparency_logging_preference

  tags = local.certificate_tags
}
