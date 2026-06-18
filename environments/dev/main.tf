# main.tf

provider "aws" {
  region = "us-east-1"

  # Skip credential validation for policy testing in CI/CD
  skip_credentials_validation = true
  skip_metadata_api_check    = true
  skip_requesting_account_id = true

  # Use mock credentials for testing
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

