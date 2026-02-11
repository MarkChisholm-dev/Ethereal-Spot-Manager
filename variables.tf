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
# Used to encrypt the EBS volumes at rest; if null, the default AWS managed key is used
variable "kms_key_arn" {
  description = "KMS Key for EBS Encryption"
  type        = string
  default     = null
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
variable "desired_capacity" { type = number; default = 10 }

# The absolute upper limit for scaling out to prevent runaway cloud costs
variable "max_size" { type = number; default = 50 }

# The absolute lower limit for scaling in; ensures the cluster never fully disappears
variable "min_size" { type = number; default = 2 }

# The shell script executed immediately upon instance startup
# Used for mounting drives, installing dependencies, or joining the HPC cluster
variable "bootstrap_script" {
  type    = string
  default = "#!/bin/bash\n# Ethereal Node Initialization\napt-get update && apt-get install -y cloud-utils"
}
