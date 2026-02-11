variable "ami_id" {
  description = "Hardened AMI ID for the compute node"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "g4dn.xlarge"
}

variable "fallback_instance_type" {
  type    = string
  default = "g5.xlarge"
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "kms_key_arn" {
  description = "KMS Key for EBS Encryption"
  type        = string
  default     = null
}

variable "disk_size" {
  type    = number
  default = 100
}

variable "on_demand_base" {
  description = "Number of guaranteed On-Demand nodes"
  type        = number
  default     = 2
}

variable "desired_capacity" { type = number; default = 10 }
variable "max_size" { type = number; default = 50 }
variable "min_size" { type = number; default = 2 }

variable "bootstrap_script" {
  type    = string
  default = "#!/bin/bash\n# Ethereal Node Initialization\napt-get update && apt-get install -y cloud-utils"
}
