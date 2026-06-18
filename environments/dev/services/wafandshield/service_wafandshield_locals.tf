locals {
  environment = "dev"
  owner       = "platform-team"

  wafandshield_name = "dev-app-waf"

  common_tags = {
    Project     = "wafandshield-demo"
    ManagedBy   = "Terraform"
    Environment = local.environment
  }
}
