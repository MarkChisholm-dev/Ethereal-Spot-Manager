# Ethereal Spot Compute Orchestrator
**Engineering Group:** Platform & Infrastructure
**Lead Contributor:** Mark Chisholm

## 1. Overview
The Ethereal Spot Compute Orchestrator is a production-grade Terraform module designed to handle high-performance computing (HPC) workloads. It manages the lifecycle of GPU-intensive clusters by leveraging AWS Mixed Instances Policies to balance cost-efficiency with operational resilience.

## 2. Problem Statement
Clients requiring large-scale data processing or AI training models often face prohibitive cloud expenditure when using standard On-Demand instances. Traditional Spot Instance usage carries the risk of sudden termination, which can disrupt long-running compute jobs.

## 3. Solution Architecture
This module implements a hybrid provisioning strategy:
* **Baseline Reliability:** Provisions a configurable base of On-Demand instances to maintain core services.
* **Elastic Scaling:** Dynamically fills additional capacity using Spot Instances.
* **Automated Fallback:** Native ASG logic handles fallback to On-Demand capacity in the event of Spot price spikes or capacity unavailability.
* **Security Compliance:** Enforces AES-256 encryption on all EBS volumes and restricts nodes to private subnets.



## 4. Technical Specifications
### 4.1 Prerequisites
* Terraform >= 1.0.0
* AWS Provider >= 4.0
* Pre-configured KMS Key for encryption

### 4.2 Module Configuration
| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `on_demand_base` | number | 2 | Minimum guaranteed On-Demand nodes. |
| `instance_type` | string | g4dn.xlarge | Primary GPU instance type. |
| `spot_strategy` | string | capacity-optimized | Allocation strategy for Spot instances. |
| `disk_size` | number | 100 | Volume size in GB. |

## 5. Deployment Example
```hcl
module "hpc_cluster" {
  source            = "./modules/ethereal-spot-manager"
  ami_id            = "ami-07c1234567890"
  subnet_ids        = ["subnet-123", "subnet-456"]
  on_demand_base    = 5
  desired_capacity  = 25
  security_group_id = "sg-0987654321"
}
