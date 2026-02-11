# Ethereal Spot Compute Orchestrator

# Passing
[![Security Compliance Scan](https://github.com/MarkChisholm-dev/Ethereal-Spot-Manager/actions/workflows/security-scan.yml/badge.svg)](https://github.com/MarkChisholm-dev/Ethereal-Spot-Manager/actions/workflows/security-scan.yml)

# Stack
[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![GitHub Actions](https://img.shields.io/badge/github%20actions-%232088FF.svg?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![Security: Trivy](https://img.shields.io/badge/Security-Trivy-blue?style=for-the-badge)](https://github.com/aquasecurity/trivy)
[![FinOps: Infracost](https://img.shields.io/badge/FinOps-Infracost-green?style=for-the-badge)](https://www.infracost.io/)

## Overview
The **Ethereal Spot Compute Orchestrator** is a specialized Terraform module engineered for High-Performance Computing (HPC) environments. It automates the provisioning of GPU-accelerated clusters by utilizing a proprietary Mixed Instances Policy, balancing mission-critical reliability with aggressive cost-optimization.

Developed as a core component of the **Ethereal Cloud Systems** infrastructure suite, this tool allows for the seamless scaling of decentralized compute nodes across multi-region AWS environments.



## Key Engineering Patterns

* **Resilient Spot Orchestration:** Implements a `capacity-optimized` allocation strategy with an automated On-Demand fallback to ensure zero downtime during Spot interruptions.
* **Encrypted Data Planes:** Enforces AES-256 EBS encryption at rest, utilizing AWS KMS for TPN-compliant (Trusted Partner Network) data security.
* **Automated FinOps:** Integrated CI/CD hooks provide real-time cost-differential analysis on every infrastructure pull request.
* **Zero-Trust Networking:** Provisions resources exclusively within isolated private subnets with strictly defined egress filtering.

## CI/CD Pipeline Architecture
This repository utilizes GitHub Actions to enforce a "Shift-Left" methodology:
1.  **Validation:** Syntactic and formatting checks via `terraform fmt` and `validate`.
2.  **Security:** Static Analysis Security Testing (SAST) via **Trivy** to prevent configuration drift.
3.  **Cost Governance:** Automated spend forecasting via **Infracost**.



## Deployment Example

```hcl
module "hpc_cluster_production" {
  source            = "git::[https://github.com/markchisholm/ethereal-spot-manager.git](https://github.com/MarkChisholm-dev/ethereal-spot-manager.git)"
  version           = "1.2.0"
  
  instance_type     = "g4dn.xlarge"
  on_demand_base    = 5
  desired_capacity  = 50
  
  # Security configuration
  kms_key_arn       = "arn:aws:kms:eu-west-1:123456789012:key/..."
  subnet_ids        = ["subnet-0a1b2c3d", "subnet-4e5f6g7h"]
}
