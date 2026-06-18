# AWS Certificate Manager Terraform Module

This Terraform module provisions and manages SSL/TLS certificates using AWS Certificate Manager (ACM). The module supports certificate creation, DNS or email validation, and comprehensive certificate lifecycle management.

## Overview

AWS Certificate Manager is a service that lets you easily provision, manage, and deploy public and private SSL/TLS certificates for use with AWS services and your internal connected resources. This module provides a standardized way to create and manage ACM certificates with built-in security best practices and compliance validation.

## Features

- SSL/TLS certificate provisioning for single or multiple domains
- Support for Subject Alternative Names (SANs)
- DNS and email validation methods
- Certificate transparency logging
- Configurable key algorithms (RSA and EC)
- Automatic certificate lifecycle management
- Comprehensive tagging support
- Built-in OPA policy validation

## Usage

### Basic Certificate

```hcl
module "certificate" {
  source = "../../modules/certificatemanager"

  domain_name       = "example.com"
  validation_method = "DNS"

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "web-application"
  }
}
```

### Wildcard Certificate

```hcl
module "wildcard_certificate" {
  source = "../../modules/certificatemanager"

  domain_name       = "*.example.com"
  validation_method = "DNS"

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "web-application"
  }
}
```

### Multi-Domain Certificate with SANs

```hcl
module "multi_domain_certificate" {
  source = "../../modules/certificatemanager"

  domain_name = "example.com"
  subject_alternative_names = [
    "www.example.com",
    "api.example.com",
    "app.example.com"
  ]
  validation_method = "DNS"

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "web-application"
  }
}
```

### Certificate with EC Key Algorithm

```hcl
module "ec_certificate" {
  source = "../../modules/certificatemanager"

  domain_name   = "example.com"
  key_algorithm = "EC_prime256v1"

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "web-application"
  }
}
```

## Certificate Validation

After creating a certificate with DNS validation, you need to add the validation DNS records to your domain's DNS configuration. The module outputs `domain_validation_options` which contains the necessary CNAME records.

### Example: Creating Route53 Validation Records

```hcl
module "certificate" {
  source = "../../modules/certificatemanager"

  domain_name       = "example.com"
  validation_method = "DNS"

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "web-application"
  }
}

# Create Route53 validation records
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in module.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# Wait for certificate validation
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = module.certificate.certificate_arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}
```

## Integration Examples

### Application Load Balancer (ALB)

```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = module.certificate.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
```

### CloudFront Distribution

```hcl
# Note: CloudFront requires certificates in us-east-1
resource "aws_cloudfront_distribution" "main" {
  # ... other configuration ...

  viewer_certificate {
    acm_certificate_arn      = module.certificate.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
```

### API Gateway Custom Domain

```hcl
resource "aws_api_gateway_domain_name" "main" {
  domain_name              = "api.example.com"
  certificate_arn          = module.certificate.certificate_arn
  security_policy          = "TLS_1_2"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| domain_name | Primary domain name for the certificate | `string` | n/a | yes |
| subject_alternative_names | Additional domain names to include in the certificate | `list(string)` | `[]` | no |
| validation_method | Certificate validation method. Valid values: DNS or EMAIL. DNS is recommended. | `string` | `"DNS"` | no |
| tags | A map of tags to assign to the certificate | `map(string)` | `{}` | no |
| certificate_transparency_logging_preference | Certificate transparency logging preference. Valid values: ENABLED or DISABLED. | `string` | `"ENABLED"` | no |
| key_algorithm | Algorithm for the certificate's private key. Valid values: RSA_2048, RSA_4096, EC_prime256v1, EC_secp384r1 | `string` | `"RSA_2048"` | no |

## Outputs

| Name | Description |
|------|-------------|
| certificate_arn | The ARN of the certificate |
| certificate_id | The ARN of the certificate (same as arn) |
| certificate_domain_name | The domain name for which the certificate is issued |
| certificate_status | The status of the certificate |
| domain_validation_options | A list of attributes to feed into other resources to complete certificate validation |
| certificate_not_after | The expiration date and time for the certificate |
| certificate_not_before | The start of the validity period of the certificate |

## Certificate Lifecycle

- **Automatic Renewal**: ACM automatically renews certificates as long as DNS validation records remain in place
- **Expiration Monitoring**: Use the `certificate_not_after` output to monitor certificate expiration
- **Replacement**: The module uses `create_before_destroy` lifecycle policy to ensure zero-downtime certificate replacement

## Security Best Practices

- **DNS Validation**: Always use DNS validation for production certificates (automated and secure)
- **Required Tags**: Include Environment, Owner, and Project tags for tracking and compliance
- **Key Algorithm**: Use RSA_2048 or higher, or EC curves for production certificates
- **Certificate Transparency**: Keep transparency logging enabled (required for compliance)
- **Regional Considerations**: CloudFront certificates must be created in us-east-1 region

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.0 |
| aws | >= 5.0.0 |

## License

This module is provided under the MIT License. See LICENSE file for details.
