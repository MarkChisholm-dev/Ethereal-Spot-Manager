# Testing the Terraform Configuration

This guide shows you how to validate and test your Terraform configuration **without creating any real infrastructure**.

## 1. Syntax Validation

Validates the configuration syntax and internal consistency:

```bash
terraform init
terraform validate
```

**What it checks:**
- HCL syntax errors
- Invalid attribute names
- Missing required arguments
- Type mismatches
- Variable validation rules

## 2. Dry Run with Plan (No AWS Credentials Needed)

You can test the configuration logic without AWS credentials:

```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit with dummy/test values (doesn't need to be real)
# Just needs to be valid format

# Run plan in dry-run mode
terraform plan
```

**What it checks:**
- Resource dependencies
- Variable interpolation
- Conditional logic
- Count/for_each expressions
- Data source references (will fail but show logic)

## 3. Plan with Mock Variables (Best for Testing)

Test without creating a tfvars file:

```bash
terraform plan \
  -var="ami_id=ami-test123456" \
  -var="kms_key_arn=arn:aws:kms:us-east-1:123456789012:key/test-key" \
  -var='subnet_ids=["subnet-test1", "subnet-test2"]' \
  -var="security_group_id=sg-test123"
```

**Note:** This will fail when Terraform tries to contact AWS, but it will validate the configuration structure first.

## 4. Static Analysis with tflint

Install and run tflint for additional validation:

```bash
# Install tflint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Run tflint
tflint --init
tflint
```

**What it checks:**
- AWS-specific best practices
- Deprecated syntax
- Potential errors
- Naming conventions

## 5. Security Scanning with Checkov

Scan for security and compliance issues:

```bash
# Install checkov
pip install checkov

# Run security scan
checkov -d . --framework terraform
```

**What it checks:**
- Security misconfigurations
- Compliance violations (CIS, PCI-DSS, etc.)
- Best practice adherence
- Known vulnerabilities

## 6. Security Scanning with Trivy (Already in CI/CD)

```bash
# Install trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Scan for misconfigurations
trivy config .
```

## 7. Cost Estimation with Infracost

Preview the cost before deployment:

```bash
# Install infracost
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Generate cost estimate
infracost breakdown --path .
```

## 8. Format Check

Ensure consistent formatting:

```bash
# Check if formatting is needed
terraform fmt -check

# Auto-format files
terraform fmt -recursive
```

## Testing Workflow (Recommended)

```bash
# Step 1: Format code
terraform fmt -recursive

# Step 2: Initialize
terraform init

# Step 3: Validate syntax
terraform validate

# Step 4: Run security scan
checkov -d . --compact --quiet

# Step 5: Lint for best practices
tflint

# Step 6: Generate plan (with test values)
terraform plan -var-file=terraform.tfvars.example -out=test.tfplan

# Step 7: Show plan details
terraform show test.tfplan

# Step 8: Estimate costs
infracost breakdown --path test.tfplan
```

## Quick Test Script

Create a file called `test.sh`:

```bash
#!/bin/bash
set -e

echo "🔍 Formatting check..."
terraform fmt -check -recursive

echo "✅ Validating configuration..."
terraform validate

echo "🔒 Running security scan..."
if command -v checkov &> /dev/null; then
    checkov -d . --compact --quiet --framework terraform
else
    echo "⚠️  Checkov not installed, skipping security scan"
fi

echo "📋 Linting..."
if command -v tflint &> /dev/null; then
    tflint
else
    echo "⚠️  tflint not installed, skipping lint"
fi

echo "✅ All tests passed!"
```

Make it executable and run:
```bash
chmod +x test.sh
./test.sh
```

## CI/CD GitHub Actions Setup

The repository has GitHub Actions configured for automated testing and deployment. To enable the **deploy workflow**, you must configure required GitHub Secrets:

### Required Secrets (for Deployment)

Set these in your GitHub repository settings: **Settings → Secrets and variables → Actions**

**AWS Authentication Secrets:**
- `AWS_ACCESS_KEY_ID` - Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret access key  
- `AWS_REGION` (optional) - AWS region (defaults to `us-east-1`)

**Terraform Variables Secrets** (populate from your AWS environment):
- `TF_VAR_AMI_ID` - EC2 AMI ID (e.g., `ami-0c55b159cbfafe1f0`)
- `TF_VAR_KMS_KEY_ARN` - KMS key ARN (e.g., `arn:aws:kms:us-east-1:123456789012:key/xxxxx`)
- `TF_VAR_SUBNET_IDS` - JSON list of subnet IDs (e.g., `["subnet-12345678", "subnet-87654321"]`)
- `TF_VAR_SECURITY_GROUP_ID` - Security group ID (e.g., `sg-0123456789abcdef0`)

### How to Add Secrets in GitHub UI

1. Navigate to your repository
2. Click **Settings**
3. Go to **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Enter the secret name and value
6. Click **Add secret**

### Example Secret Values

| Secret Name | Example Value |
|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | `us-east-1` |
| `TF_VAR_AMI_ID` | `ami-0c55b159cbfafe1f0` |
| `TF_VAR_KMS_KEY_ARN` | `arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012` |
| `TF_VAR_SUBNET_IDS` | `["subnet-12345678", "subnet-87654321"]` |
| `TF_VAR_SECURITY_GROUP_ID` | `sg-0123456789abcdef0` |

### ⚠️ Important Security Notes

- **Never commit secrets** to your repository (they're git-ignored for `.tfvars`)
- **Use minimal permissions** - Create IAM users with only required permissions
- **Rotate credentials regularly** - Update GitHub secrets quarterly
- **Use AWS temporary credentials** when possible (STS)
- **Secrets are encrypted** by GitHub and never logged in workflow output

### Managing Variable Files Locally

For **local testing**, you can create an untracked `terraform.tfvars` file:

```bash
# Create from example
cp terraform.tfvars.example terraform.tfvars

# Edit with your real values
vi terraform.tfvars

# This file is in .gitignore, so it won't be committed
git status  # terraform.tfvars should NOT appear
```

## CI/CD (Already Configured)

The repository already has GitHub Actions configured for:
- ✅ Terraform format check
- ✅ Terraform validation
- ✅ Security scanning with Trivy
- ✅ Cost analysis with Infracost

These run automatically on every pull request!

## What You CANNOT Test Without Real Infrastructure

- **Provider authentication** - Requires real AWS credentials
- **Resource existence** - Checking if AMIs, subnets, etc. actually exist
- **IAM permissions** - Whether your credentials can create resources
- **Actual costs** - Real billing (Infracost gives estimates)
- **Runtime behavior** - How instances actually perform

## Summary

**Level 1 - No Tools Needed:**
- `terraform fmt -check`
- `terraform validate`

**Level 2 - With Test Values:**
- `terraform plan` (with dummy variables)

**Level 3 - Additional Tools:**
- `tflint` for best practices
- `checkov` or `trivy` for security
- `infracost` for cost estimation

**Level 4 - Full Integration:**
- Use Terraform Cloud/Enterprise with policy as code
- Sentinel policies
- OPA (Open Policy Agent)

Start with Level 1-2, then add tools as needed!
