# The unique identifier for the Amazon Machine Image
# This should point to a pre-configured image with GPU drivers and security hardening
variable "ami_id" {
  description = "Hardened AMI ID for the compute node"
  type        = string
}

# The primary hardware profile for the compute nodes
# Defaults to g4dn.xlarge (NVIDIA T4 Tensor Core GPU) for cost-effective inference/training
variable "instance_type" {
  type    = string
  default = "g4dn.xlarge"
}

# The secondary hardware profile used if the primary Spot capacity is unavailable
# Defaults to g5.xlarge (NVIDIA A10G Tensor Core GPU) to ensure fleet availability
variable "fallback_instance_type" {
  type    = string
  default = "g5.xlarge"
}

# A list of VPC subnet identifiers where the instances will be provisioned
# These should typically be private subnets for TPN/Security compliance
variable "subnet_ids" {
  type = list(string)
}

# The ID of the Security Group that defines firewall rules for the fleet
variable "security_group_id" {
  type = string
}

# The Amazon Resource Name for the Key Management Service key
# Used to encrypt the EBS volumes at rest; required for TPN compliance
variable "kms_key_arn" {
  description = "KMS Key for EBS Encryption (required for compliance)"
  type        = string

  validation {
    condition     = var.kms_key_arn != null && can(regex("^arn:aws:kms:", var.kms_key_arn))
    error_message = "KMS key ARN is required for encryption compliance and must be a valid ARN."
  }
}

# The size of the root storage volume in Gigabytes
# Defaulting to 100GB provides ample space for large datasets and container images
variable "disk_size" {
  type    = number
  default = 100
}

# The minimum number of instances that must run on the reliable "On-Demand" pricing model
# This ensures a baseline of 2 nodes that won't be interrupted by Spot price spikes
variable "on_demand_base" {
  description = "Number of guaranteed On-Demand nodes"
  type        = number
  default     = 2
}

# The target number of instances the fleet should aim to maintain during normal operation
variable "desired_capacity" {
  description = "Target number of instances to maintain"
  type        = number
  default     = 10
}

# The absolute upper limit for scaling out to prevent runaway cloud costs
variable "max_size" {
  description = "Maximum number of instances allowed in the fleet"
  type        = number
  default     = 50
}

# The absolute lower limit for scaling in; ensures the cluster never fully disappears
variable "min_size" {
  description = "Minimum number of instances to maintain"
  type        = number
  default     = 2
}

# The shell script executed immediately upon instance startup
# Used for mounting drives, installing dependencies, or joining the HPC cluster
variable "bootstrap_script" {
  description = "User data script for instance initialization"
  type        = string
  default     = "#!/bin/bash\n# Ethereal Node Initialization\napt-get update && apt-get install -y cloud-utils"
}

# EBS root device name (varies by AMI: /dev/xvda for most, /dev/sda1 for some)
variable "root_device_name" {
  description = "Root block device name for the AMI"
  type        = string
  default     = "/dev/xvda"
}

# gp3 volume IOPS for enhanced performance
variable "ebs_iops" {
  description = "Provisioned IOPS for gp3 volumes (3000-16000)"
  type        = number
  default     = 3000

  validation {
    condition     = var.ebs_iops >= 3000 && var.ebs_iops <= 16000
    error_message = "IOPS must be between 3000 and 16000 for gp3 volumes."
  }
}

# gp3 volume throughput for enhanced performance
variable "ebs_throughput" {
  description = "Provisioned throughput for gp3 volumes in MiB/s (125-1000)"
  type        = number
  default     = 125

  validation {
    condition     = var.ebs_throughput >= 125 && var.ebs_throughput <= 1000
    error_message = "Throughput must be between 125 and 1000 MiB/s for gp3 volumes."
  }
}

# Health check type for Auto Scaling Group
variable "health_check_type" {
  description = "Type of health check (EC2 or ELB)"
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "Health check type must be either EC2 or ELB."
  }
}

# Grace period before health checks start
variable "health_check_grace_period" {
  description = "Time in seconds before health checks begin after instance launch"
  type        = number
  default     = 300
}

# Maximum instance lifetime for forced refresh
variable "max_instance_lifetime" {
  description = "Maximum time in seconds an instance can run (0 = unlimited)"
  type        = number
  default     = 604800 # 1 week
}

# Environment tag for cost attribution
variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string
  default     = "production"
}

# Cost center tag for FinOps
variable "cost_center" {
  description = "Cost center or department for billing attribution"
  type        = string
  default     = "HPC-Engineering"
}

# Project tag for resource grouping
variable "project" {
  description = "Project name for resource organization"
  type        = string
  default     = "Ethereal-Cloud-Systems"
}

# SNS topic for scaling notifications (optional)
variable "sns_topic_arn" {
  description = "SNS topic ARN for scale event notifications (optional)"
  type        = string
  default     = null
}

# Enable auto scaling based on CPU utilization
variable "enable_cpu_scaling" {
  description = "Enable CPU-based auto scaling policy"
  type        = bool
  default     = true
}

# Target CPU utilization percentage for auto scaling
variable "target_cpu_utilization" {
  description = "Target CPU utilization percentage for auto scaling"
  type        = number
  default     = 70

  validation {
    condition     = var.target_cpu_utilization > 0 && var.target_cpu_utilization <= 100
    error_message = "Target CPU utilization must be between 1 and 100."
  }
}
