# Ethereal Cloud Systems - HPC Infrastructure Suite
# Component: Automated Spot-to-On-Demand Provisioning
# Purpose: Maintain high-availability for GPU-intensive workloads while optimizing spend.

resource "aws_launch_template" "hpc_node" {
  name_prefix   = "ethereal-hpc-node-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  # Security: Hardened Network Interface
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security_group_id]
  }

  # Compliance: ISO 27001 / TPN Encrypted Storage
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 100
      encrypted   = true
      kms_key_id  = var.kms_key_arn
    }
  }

  user_data = base64encode(var.bootstrap_script)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Org     = "Ethereal-HPC"
      Tier    = "Compute"
      Env     = "Production"
      ManagedBy = "Terraform"
    }
  }
}

resource "aws_autoscaling_group" "compute_fleet" {
  name                = "ethereal-compute-fleet"
  vpc_zone_identifier = var.subnet_ids
  max_size            = var.max_size
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = var.on_demand_base
      on_demand_percentage_above_base_capacity = 0 # 100% Spot above the base for max savings
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.hpc_node.id
        version            = "$Latest"
      }
    }
  }
}
