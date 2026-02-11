# Ethereal Cloud Systems - HPC Infrastructure Suite
# Component: Automated Spot-to-On-Demand Provisioning
# Focus: High-availability GPU scaling with TPN-compliant security

resource "aws_launch_template" "hpc_node" {
  name_prefix   = "ethereal-hpc-node-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  # Performance: Dedicated EBS bandwidth for HPC workloads
  ebs_optimized = true

  # Monitoring: Detailed CloudWatch metrics (1-minute intervals) for GPU scaling
  monitoring {
    enabled = true
  }

  # FIX: Enforce IMDSv2 (Tokens Required)
  # Resolves AVD-AWS-0130 and blocks SSRF credential theft
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" 
    http_put_response_hop_limit = 1 # Prevents token leakage to containers
  }

  # Security: Hardened Network Interface (Private Subnet Only)
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security_group_id]
    delete_on_termination       = true
  }

  # Compliance: AES-256 Encryption at Rest (TPN / ISO 27001)
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp3" # Higher baseline performance for HPC
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }

  user_data = base64encode(var.bootstrap_script)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Organization = "Ethereal-Cloud-Systems"
      Component    = "HPC-Compute-Node"
      ManagedBy    = "Terraform"
      Security     = "Hardened"
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
      on_demand_percentage_above_base_capacity = 0 # 100% Spot above the base for cost efficiency
      spot_allocation_strategy                 = "capacity-optimized" # Reduces interruption rates
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.hpc_node.id
        version            = "$Latest"
      }
      
      # Flexibility for Spot availability
      override { instance_type = var.instance_type }
      override { instance_type = var.fallback_instance_type }
    }
  }

  # Ensures updates to the Launch Template are rolled out to the fleet automatically
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "ethereal-hpc-worker"
    propagate_at_launch = true
  }
}
