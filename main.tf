# Ethereal Cloud Systems - HPC Infrastructure Suite
# Component: Automated Spot-to-On-Demand Provisioning
# Focus: High-availability GPU scaling with TPN-compliant security

resource "aws_launch_template" "hpc_node" {
  name_prefix   = "ethereal-hpc-node-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  # FIX: Enforce IMDSv2 (Tokens Required)
  # This resolves AVD-AWS-0130 and prevents SSRF vulnerabilities
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" 
    http_put_response_hop_limit = 1
  }

  # Security: Hardened Network Interface
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security_group_id]
  }

  # Compliance: AES-256 Encryption at Rest (TPN / ISO 27001)
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.disk_size
      encrypted   = true
      kms_key_id  = var.kms_key_arn
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
      on_demand_percentage_above_base_capacity = 0 # 100% Spot above the base
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.hpc_node.id
        version            = "$Latest"
      }
      
      # Instance flexibility to ensure Spot availability in tight markets
      override {
        instance_type = var.instance_type
      }
      override {
        instance_type = var.fallback_instance_type
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
