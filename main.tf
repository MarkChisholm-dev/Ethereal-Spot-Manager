# Ethereal Cloud Systems - HPC Infrastructure Suite
# Component: Automated Spot-to-On-Demand Provisioning
# Focus: High-availability GPU scaling with TPN-compliant security

# Centralized tag definitions for consistent resource labeling
locals {
  common_tags = {
    Organization = var.project
    Component    = "HPC-Compute-Node"
    ManagedBy    = "Terraform"
    Security     = "Hardened"
    Environment  = var.environment
    CostCenter   = var.cost_center
    Project      = var.project
  }
}

# Defines a reusable template for launching EC2 instances with consistent settings
resource "aws_launch_template" "hpc_node" {
  # Assigns a name prefix; AWS will append a unique identifier to the end
  name_prefix = "ethereal-hpc-node-"
  # The Amazon Machine Image ID provided via a variable
  image_id = var.ami_id
  # The specific EC2 hardware type (e.g., p4d.24xlarge) provided via variable
  instance_type = var.instance_type

  # Performance: Dedicated EBS bandwidth for HPC workloads
  # Ensures the instance has dedicated throughput to the storage volume
  ebs_optimized = true

  # Monitoring: Detailed CloudWatch metrics (1-minute intervals) for GPU scaling
  monitoring {
    # Enables 1-minute data granularity instead of the default 5-minute
    enabled = true
  }

  # FIX: Enforce IMDSv2 (Tokens Required)
  # Resolves AVD-AWS-0130 and blocks SSRF credential theft
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    http_protocol_ipv6          = "disabled"
    instance_metadata_tags      = "enabled"
  }

  # Security: Hardened Network Interface (Private Subnet Only)
  network_interfaces {
    # Disables public IP assignment to keep the node off the public internet
    associate_public_ip_address = false
    # Attaches the firewall rules defined in the security group variable
    security_groups = [var.security_group_id]
    # Ensures the network interface is cleaned up when the instance is deleted
    delete_on_termination = true
  }

  # Compliance: AES-256 Encryption at Rest (TPN / ISO 27001)
  block_device_mappings {
    device_name = var.root_device_name
    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp3"
      iops                  = var.ebs_iops
      throughput            = var.ebs_throughput
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }

  # Converts the shell script variable into a base64 string for AWS to execute on boot
  user_data = base64encode(var.bootstrap_script)

  # Applies tags specifically to the EC2 instances created from this template
  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "ethereal-hpc-worker" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(local.common_tags, { Name = "ethereal-hpc-volume" })
  }
}

# Manages the collection of instances, handling scaling and health checks
resource "aws_autoscaling_group" "compute_fleet" {
  name                      = "ethereal-compute-fleet"
  vpc_zone_identifier       = var.subnet_ids
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  max_instance_lifetime     = var.max_instance_lifetime
  capacity_rebalance        = true
  termination_policies      = ["OldestLaunchTemplate", "Default"]

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  # Configuration for using a mix of On-Demand and Spot instances
  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = var.on_demand_base
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "capacity-optimized"
    }

    # Links the ASG to the Launch Template defined above
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.hpc_node.id
        version            = "$Latest"
      }

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

  # Meta-argument to handle resource replacement order
  lifecycle {
    create_before_destroy = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value               = "ethereal-hpc-worker"
    propagate_at_launch = true
  }
}

# Auto Scaling Policy: CPU-based target tracking
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  count                  = var.enable_cpu_scaling ? 1 : 0
  name                   = "ethereal-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.compute_fleet.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.target_cpu_utilization
  }
}

# SNS Notification Configuration for scale events
resource "aws_autoscaling_notification" "fleet_notifications" {
  count = var.sns_topic_arn != null ? 1 : 0

  group_names = [aws_autoscaling_group.compute_fleet.name]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = var.sns_topic_arn
}
