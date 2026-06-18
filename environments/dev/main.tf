# main.tf

provider "aws" {
  region = var.region

  # Skip credential validation for OPA policy testing
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  # Use dummy credentials for plan generation
  access_key = "mock_access_key"
  secret_key = "mock_secret_key"
}

terraform {
  required_version = ">= 1.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.37.0"
    }
  }
}

