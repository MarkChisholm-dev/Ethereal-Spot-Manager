# Ethereal Spot Manager - Workflow Documentation

This directory contains GitHub Actions workflows for continuous integration, security scanning, testing, and deployment.

## Workflow Overview

### 🔍 [validate.yml](validate.yml)
**Purpose:** Format, syntax, and best practices validation
- **Triggers:** On push/PR to main, when `.tf` files change
- **Jobs:**
  - `terraform` - Format and syntax checks
  - `tflint` - Best practices linting
- **Output:** PR comments with validation results

### 🔒 [security.yml](security.yml)
**Purpose:** Comprehensive security scanning
- **Triggers:** On push/PR to main, daily schedule (2 AM UTC)
- **Jobs:**
  - `trivy` - Infrastructure misconfiguration scanning
  - `checkov` - Policy as Code validation
  - `semgrep` - Code pattern detection
- **Output:** SARIF reports, PR comments with findings

### 🧪 [test.yml](test.yml)
**Purpose:** Configuration testing and validation
- **Triggers:** On push/PR to main, when `.tf` files change
- **Jobs:**
  - `plan-test` - Generate test plan with example values
  - `shell-check` - Validate shell scripts (test.sh)
  - `documentation` - Check required files exist
- **Output:** PR comments with test results

### 📋 [plan.yml](plan.yml)
**Purpose:** Generate Terraform plans for pull requests
- **Triggers:** On PR to main when `.tf` files change
- **Jobs:**
  - `plan` - Generate and display Terraform plan
  - `estimate-cost` - Estimated infrastructure costs (requires INFRACOST_API_KEY)
  - `resource-summary` - Display resource summary
- **Output:** Detailed PR comments with plan, costs, and resources

### 📚 [docs.yml](docs.yml)
**Purpose:** Documentation quality checks
- **Triggers:** On push/PR when documentation changes
- **Jobs:**
  - `markdown-lint` - Markdown formatting validation
  - `link-check` - Verify documentation links
  - `spell-check` - Spell checking
  - `update-toc` - Verify required sections
- **Output:** Quality feedback on documentation

### 🚀 [deploy.yml](deploy.yml)
**Purpose:** Production deployment (requires manual approval)
- **Triggers:** On push to main with AWS credentials
- **Jobs:**
  - `pre-deploy-checks` - Validation before deployment
  - `plan` - Generate production plan
  - `approval` - Create approval issue for manual review
  - `deploy` - Apply Terraform (conditional on approval)
- **Requirements:**
  - `AWS_ACCESS_KEY_ID` secret
  - `AWS_SECRET_ACCESS_KEY` secret
  - `AWS_REGION` secret (optional, defaults to us-east-1)

## Configuration

### Required Secrets

For deployment workflows to work, add these to GitHub repo settings:

```
Settings → Secrets and variables → Actions → New repository secret
```

**For Deployment:**
- `AWS_ACCESS_KEY_ID` - AWS IAM access key
- `AWS_SECRET_ACCESS_KEY` - AWS IAM secret key
- `AWS_REGION` - Target AWS region (optional, default: us-east-1)

**For Cost Estimation (Optional):**
- `INFRACOST_API_KEY` - Get from https://dashboard.infracost.io

### Environment Setup

For production deployments, create an environment:

```
Settings → Environments → New environment
Name: production
Add deployment branches: main
Add required reviewers: (your team members)
```

## Workflow Execution Flow

```
┌─────────────────────────────────────┐
│ Push/PR to main                     │
└────────────┬────────────────────────┘
             │
             ├─→ ✅ validate.yml
             │   ├─ Format check
             │   └─ TFLint
             │
             ├─→ 🔒 security.yml
             │   ├─ Trivy scan
             │   ├─ Checkov policies
             │   └─ Semgrep patterns
             │
             ├─→ 🧪 test.yml
             │   ├─ Plan test
             │   ├─ Shell check
             │   └─ Documentation
             │
             ├─→ 📋 plan.yml (only on PR)
             │   ├─ Terraform plan
             │   ├─ Cost estimate
             │   └─ Resource summary
             │
             └─→ 📚 docs.yml (documentation changes)
                 ├─ Markdown lint
                 ├─ Link check
                 └─ Spell check

             IF all pass AND push to main:
             │
             └─→ 🚀 deploy.yml
                 ├─ Pre-deploy checks
                 ├─ Generate plan
                 ├─ Request approval
                 └─ Deploy (if approved)
```

## PR Checklist

Before merging, ensure:

- [ ] ✅ validate.yml passed - No format or syntax errors
- [ ] 🔒 security.yml passed - No critical security issues
- [ ] 🧪 test.yml passed - Configuration is valid
- [ ] 📋 plan.yml passed - Plan shows expected changes
- [ ] 📚 docs.yml passed - Documentation is updated
- [ ] All comments addressed - PR review complete

## Troubleshooting

### Validation Failures

**Format errors:**
```bash
terraform fmt -recursive
git add .
git commit -m "chore: format Terraform files"
git push
```

**Syntax errors:**
```bash
terraform validate
# Fix errors shown, then push again
```

### Security Issues

**Trivy findings:**
- Review findings in job logs
- Update security groups/IAM policies as needed
- Or skip with `skip-check` parameter in workflow

**Checkov violations:**
- Review policy violations
- Justify exceptions in comments
- Or add to skip list

### Deployment Issues

1. Check AWS credentials are set correctly
2. Verify IAM permissions for your user
3. Review approval issue for feedback
4. Check job logs for detailed errors

## Customization

### Add Workflow Triggers

Edit trigger conditions in `on:` section:

```yaml
on:
  push:
    branches: [ main, develop ]
    paths:
      - '**.tf'
```

### Skip Workflow Steps

Use `continue-on-error: true` for non-blocking steps:

```yaml
- name: Step Name
  run: command
  continue-on-error: true
```

### Add Notifications

Add Slack/email notifications to job completion:

```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1.24.0
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
```

## Status Badges

Add these to your README:

```markdown
![Validate](https://github.com/MarkChisholm-dev/Ethereal-Spot-Manager/workflows/🔍%20Validate%20&%20Lint/badge.svg)
![Security](https://github.com/MarkChisholm-dev/Ethereal-Spot-Manager/workflows/🔒%20Security%20Scan/badge.svg)
![Test](https://github.com/MarkChisholm-dev/Ethereal-Spot-Manager/workflows/🧪%20Test%20Suite/badge.svg)
```

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Best Practices](https://terraform.io/docs/cloud/guides/recommended-practices)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
