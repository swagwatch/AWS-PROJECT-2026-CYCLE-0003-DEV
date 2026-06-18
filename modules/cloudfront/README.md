# AWS CloudFront Terraform Module

Production-ready Terraform module for deploying and managing AWS CloudFront distributions with integrated security policy validation.

## Features

- **Comprehensive CloudFront Configuration**: Support for origins, cache behaviors, SSL/TLS, logging, WAF integration, and geo-restrictions
- **Origin Access Control (OAC)**: Secure S3 origin access without public buckets
- **Multiple Origin Types**: S3 origins and custom origins (ALB, EC2, external servers)
- **Cache Behavior Management**: Default and ordered cache behaviors with flexible TTL configuration
- **SSL/TLS Security**: Enforced TLSv1.2+ with custom or CloudFront default certificates
- **Logging & Monitoring**: CloudFront access logging for security and troubleshooting
- **WAF Integration**: AWS WAF protection against common web exploits
- **Geo-Restrictions**: Content restriction by geographic location
- **Custom Error Pages**: Branded error responses for better user experience
- **Automatic Tagging**: Required and custom tags for resource organization
- **OPA Policy Validation**: Automated security policy checks before deployment

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.0 |
| aws | >= 5.0.0, < 6.0.0 |

## Usage

### Basic S3 Origin Example

```hcl
module "cloudfront" {
  source = "../../modules/cloudfront"

  environment = "dev"
  owner       = "platform-team"
  project     = "cdn"

  origins = [{
    domain_name = "my-bucket.s3.us-east-1.amazonaws.com"
    origin_id   = "S3-my-bucket"
  }]

  create_origin_access_control = true
  origin_access_control_name   = "my-oac"

  default_cache_behavior = {
    target_origin_id       = "S3-my-bucket"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    forwarded_values = {
      query_string = false
      cookies      = { forward = "none" }
    }
  }

  viewer_certificate = {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  logging_config = {
    enabled = true
    bucket  = "my-logs.s3.amazonaws.com"
    prefix  = "cloudfront/"
  }
}
```

### Custom Origin (ALB) Example

```hcl
module "cloudfront" {
  source = "../../modules/cloudfront"

  environment = "prod"
  owner       = "platform-team"
  project     = "api"

  origins = [{
    domain_name = "api.example.com"
    origin_id   = "ALB-api"
    custom_origin_config = {
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 60
    }
  }]

  default_cache_behavior = {
    target_origin_id       = "ALB-api"
    viewer_protocol_policy = "https-only"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed CachingOptimized
  }

  viewer_certificate = {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  web_acl_id = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/prod/a1b2c3d4"

  aliases = ["cdn.example.com"]

  logging_config = {
    enabled = true
    bucket  = "prod-logs.s3.amazonaws.com"
    prefix  = "cloudfront/api/"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| owner | Owner or team responsible for this resource | `string` | n/a | yes |
| project | Project name | `string` | `""` | no |
| enabled | Whether the CloudFront distribution is enabled | `bool` | `true` | no |
| origins | List of origin configurations | `list(object)` | n/a | yes |
| default_cache_behavior | Default cache behavior configuration | `object` | n/a | yes |
| viewer_certificate | SSL/TLS certificate configuration | `object` | CloudFront default | no |
| logging_config | Logging configuration | `object` | disabled | no |
| price_class | Price class (PriceClass_All, PriceClass_200, PriceClass_100) | `string` | `"PriceClass_100"` | no |
| web_acl_id | WAF Web ACL ARN | `string` | `""` | no |
| default_root_object | Default root object | `string` | `"index.html"` | no |
| aliases | Custom domain names (CNAMEs) | `list(string)` | `[]` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

See [variables.tf](./variables.tf) for complete input documentation.

## Outputs

| Name | Description |
|------|-------------|
| distribution_id | CloudFront distribution ID |
| distribution_arn | CloudFront distribution ARN |
| distribution_domain_name | CloudFront domain name (e.g., d111111abcdef8.cloudfront.net) |
| distribution_hosted_zone_id | Route53 hosted zone ID for CloudFront (Z2FDTNDATAQYW2) |
| distribution_status | Distribution status (Deployed, InProgress) |
| origin_access_control_id | Origin Access Control ID (if created) |

## Security Considerations

This module integrates with OPA (Open Policy Agent) policies that enforce security best practices:

### CRITICAL Rules (deny deployment):
- **HTTPS Enforcement**: Viewer protocol must be https-only or redirect-to-https
- **TLS Version**: Minimum TLS version must be TLSv1.2_2021 or TLSv1.3_2021
- **Required Tags**: Environment and Owner tags must be present
- **Secure Origins**: Custom origins cannot use http-only protocol
- **Default Root Object**: Must be set to prevent directory listing exposure
- **Production Logging**: Logging required for production environments
- **Production WAF**: WAF Web ACL required for production environments

### WARNING Rules (non-blocking):
- **Cost Optimization**: Warn if using expensive PriceClass_All
- **Compression**: Recommend enabling compression for bandwidth savings
- **HTTP Version**: Suggest using HTTP/2 or HTTP/3 for better performance
- **Origin Timeouts**: Warn if origin read timeout exceeds 60 seconds
- **Cache TTL**: Warn if max TTL exceeds 1 year

## CloudFront-Specific Notes

### Origin Access Control (OAC) for S3
OAC is the modern replacement for Origin Access Identity (OAI). To use OAC with S3:

1. Set `create_origin_access_control = true`
2. Update S3 bucket policy to allow CloudFront distribution ARN
3. Ensure S3 bucket is not publicly accessible

### Cache Policies vs. Legacy Settings
- Use `cache_policy_id` for managed or custom cache policies (recommended)
- Use `forwarded_values`, `min_ttl`, `default_ttl`, `max_ttl` for legacy behavior
- Cannot mix cache policies with legacy settings

### SSL/TLS Certificates
- CloudFront default certificate: Free, works with `*.cloudfront.net` domain
- Custom certificate: Requires ACM certificate in `us-east-1` region, enables custom domains (aliases)

### Invalidations
Content updates require cache invalidations. Use AWS CLI or Terraform resource:
```bash
aws cloudfront create-invalidation --distribution-id E1234567890ABC --paths "/*"
```

## License

See repository LICENSE file.
