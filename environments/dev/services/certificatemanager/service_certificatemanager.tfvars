# Certificate domain configuration
domain_name = "dev.example.com"

# Additional domain names for the certificate
subject_alternative_names = ["*.dev.example.com"]

# Certificate validation method (DNS is recommended)
validation_method = "DNS"

# Key algorithm for certificate security
key_algorithm = "RSA_2048"

# Certificate transparency logging (required for compliance)
certificate_transparency_logging_preference = "ENABLED"

# Environment and ownership tags
environment = "dev"
owner       = "platform-team"
project     = "certificatemanager-module"
