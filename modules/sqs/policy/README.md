# OPA Rego Policies for AWS SQS

## Overview

This directory contains Open Policy Agent (OPA) Rego policies for validating Terraform plans that provision AWS SQS queues. These policies enforce security best practices and provide cost optimization recommendations before infrastructure is deployed.

## Policy Rules

### CRITICAL Rules (DENY)

These rules will **fail** the policy validation and block deployment if violated:

#### 1. Encryption Required
- **Rule**: SQS queue must be encrypted with KMS
- **Violation Message**: `SQS queue must be encrypted with KMS. Specify kms_master_key_id. Resource: <address>`
- **Description**: All SQS queues must use server-side encryption with AWS KMS customer managed keys. This protects sensitive data at rest and ensures compliance with data security policies.

#### 2. Environment Tag Required
- **Rule**: SQS queue must have required tag 'Environment'
- **Violation Message**: `Missing required tag 'Environment' on SQS queue. Resource: <address>`
- **Description**: The Environment tag is mandatory for cost allocation, resource organization, and environment identification (dev, staging, production).

#### 3. Owner Tag Required
- **Rule**: SQS queue must have required tag 'Owner'
- **Violation Message**: `Missing required tag 'Owner' on SQS queue. Resource: <address>`
- **Description**: The Owner tag identifies the team or individual responsible for the queue, enabling accountability and proper resource management.

#### 4. No Wildcard Principals in Queue Policy
- **Rule**: SQS queue policy must not use wildcard principal '*'
- **Violation Message**: `SQS queue policy must not use wildcard principal '*'. Specify explicit principals. Resource: <address>`
- **Description**: Queue policies must specify explicit AWS principals (account IDs, IAM roles, or services) rather than using wildcard `*`. Wildcard principals allow unrestricted access from any AWS account, creating a critical security vulnerability.

### WARNING Rules (WARN)

These rules generate **warnings** but do not block deployment:

#### 1. High Visibility Timeout
- **Rule**: Visibility timeout > 5 minutes
- **Warning Message**: `Visibility timeout is high (>5 minutes). Review if necessary to avoid message processing delays. Resource: <address>`
- **Description**: A visibility timeout greater than 300 seconds (5 minutes) may indicate that message processing takes too long or that the timeout is unnecessarily high, which can delay message reprocessing in case of failures.

#### 2. High Message Retention
- **Rule**: Message retention > 14 days
- **Warning Message**: `Message retention is high (>14 days). Consider shorter retention to reduce storage costs. Resource: <address>`
- **Description**: Message retention beyond 1,209,600 seconds (14 days, the AWS maximum) is unnecessary and increases storage costs. Consider whether messages really need to be retained for the full 14 days.

## Usage

### Validate Policy Syntax

Check that the Rego policies have valid syntax:

```bash
opa check modules/sqs/policy/main.rego modules/sqs/policy/test.rego
```

### Run Policy Tests

Execute the unit tests to verify policy behavior:

```bash
opa test modules/sqs/policy/ -v
```

Expected output:
```
data.terraform.aws.sqs.test_valid_configuration_no_violations: PASS
data.terraform.aws.sqs.test_invalid_configuration_with_violations: PASS
data.terraform.aws.sqs.test_delete_action_ignored: PASS
data.terraform.aws.sqs.test_wildcard_policy_violation: PASS
--------------------------------------------------------------------------------
PASS: 4/4
```

### Evaluate Policies Against Terraform Plan

1. Generate a Terraform plan:
```bash
terraform plan -out=tfplan.binary
```

2. Convert the plan to JSON:
```bash
terraform show -json tfplan.binary > tfplan.json
```

3. Evaluate the deny rules:
```bash
opa eval -i tfplan.json -d modules/sqs/policy/main.rego "data.terraform.aws.sqs.deny"
```

4. Check for violations (fail if any exist):
```bash
opa eval -i tfplan.json -d modules/sqs/policy/main.rego --fail "count(data.terraform.aws.sqs.deny) > 0"
```

If violations exist, the command exits with code 1 and displays the violation messages.

5. Evaluate the warn rules:
```bash
opa eval -i tfplan.json -d modules/sqs/policy/main.rego "data.terraform.aws.sqs.warn"
```

## Testing

The `test.rego` file contains four test cases:

### 1. Valid Configuration (No Violations)
- Tests that a properly configured SQS queue with encryption and required tags passes all deny rules
- Verifies that no false positives are generated for compliant configurations

### 2. Invalid Configuration (Multiple Violations)
- Tests that a queue without encryption and missing required tags triggers exactly 3 deny violations
- Verifies that all security rules are properly enforced

### 3. Delete Action Ignored
- Tests that resources being deleted (actions = ["delete"]) do not trigger policy validation
- Ensures policies only validate resource creation and updates, not deletions

### 4. Wildcard Policy Violation
- Tests that queue policies containing `Principal: "*"` trigger a deny violation
- Verifies protection against overly permissive access policies

## Integration

### Build System Integration

The build system in `environments/dev/.onekloud_init/` automatically copies `main.rego` to `environments/dev/opa-policies/service_sqs_policies.rego` during the build process. This enables policy validation as part of the deployment pipeline.

### CI/CD Integration

These policies should be integrated into your CI/CD pipeline to validate infrastructure changes before deployment:

1. Run `terraform plan` to generate the execution plan
2. Convert the plan to JSON format
3. Evaluate the OPA policies against the plan JSON
4. Fail the pipeline if any CRITICAL violations are found
5. Report WARNINGS but allow deployment to proceed

Example CI/CD pipeline step:
```yaml
- name: Validate OPA Policies
  run: |
    terraform plan -out=tfplan.binary
    terraform show -json tfplan.binary > tfplan.json
    opa eval -i tfplan.json -d opa-policies/service_sqs_policies.rego --fail "count(data.terraform.aws.sqs.deny) > 0"
```

## Policy Development

### Adding New Rules

To add new policy rules:

1. Add the rule to `main.rego` in the appropriate section (deny or warn)
2. Add corresponding test cases to `test.rego`
3. Run `opa check` to validate syntax
4. Run `opa test` to verify the rule behaves as expected
5. Update this README with the new rule documentation

### Helper Functions

The policies use several helper functions defined in `main.rego`:

- **`resource_changes_by_type(res_type)`**: Returns resources of the specified type that are being created or updated
- **`get_tags(after)`**: Extracts tags from a resource's after state, handling both `tags` and `tags_all` attributes
- **`array_contains(arr, v)`**: Checks if an array contains a specific value
