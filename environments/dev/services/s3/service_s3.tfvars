bucket_name = "dev-example-app-data"

encryption_type = "AES256"

versioning_enabled = true

lifecycle_rules = [
  {
    id      = "archive-old-objects"
    enabled = true
    prefix  = "logs/"

    transitions = [
      {
        days          = 90
        storage_class = "STANDARD_IA"
      },
      {
        days          = 180
        storage_class = "GLACIER"
      }
    ]

    expiration = {
      days = 365
    }
  }
]

logging_target_bucket = "dev-logs-bucket"
logging_target_prefix = "s3-access-logs/"

tags = {
  Environment = "dev"
  Owner       = "platform-team"
  Project     = "example-app"
}
