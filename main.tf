# Ethereal Cloud Systems - HPC Infrastructure Suite
# Component: Automated Spot-to-On-Demand Provisioning
# Focus: High-availability GPU scaling with TPN-compliant security

# Defines a reusable template for launching EC2 instances with consistent settings
resource "aws_launch_template" "hpc_node" {
  # Assigns a name prefix; AWS will append a unique identifier to the end
  name_prefix   = "ethereal-hpc-node-"
  # The Amazon Machine Image ID provided via a variable
  image_id      = var.ami_id
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
    # Enables the Instance Metadata Service
    http_endpoint               = "enabled"
    # Forces the use of session tokens (IMDSv2), preventing unauthorized metadata access
    http_tokens                 = "required" 
    # Limits the token to 1 network hop to prevent it from escaping to a container or proxy
    http_put_response_hop_limit = 1 
  }

  # Security: Hardened Network Interface (Private Subnet Only)
  network_interfaces {
    # Disables public IP assignment to keep the node off the public internet
    associate_public_ip_address = false
    # Attaches the firewall rules defined in the security group variable
    security_groups             = [var.security_group_id]
    # Ensures the network interface is cleaned up when the instance is deleted
    delete_on_termination       = true
  }

  # Compliance: AES-256 Encryption at Rest (TPN / ISO 27001)
  block_device_mappings {
    # Defines the primary root drive location
    device_name = "/dev/xvda"
    ebs {
      # The storage capacity in GB provided via variable
      volume_size           = var.disk_size
      # Uses gp3, which allows independent scaling of IOPS and throughput
      volume_type           = "gp3" 
      # Enables hardware-level encryption for the data
      encrypted             = true
      # Uses a specific Customer Managed Key (CMK) for encryption control
      kms_key_id            = var.kms_key_arn
      # Automatically wipes the storage when the instance is terminated
      delete_on_termination = true
    }
  }

  # Converts the shell script variable into a base64 string for AWS to execute on boot
  user_data = base64encode(var.bootstrap_script)

  # Applies tags specifically to the EC2 instances created from this template
  tag_specifications {
    # Targets the 'instance' resource type for tagging
    resource_type = "instance"
    tags = {
      Organization = "Ethereal-Cloud-Systems"
      Component    = "HPC-Compute-Node"
      ManagedBy    = "Terraform"
      Security     = "Hardened"
    }
  }
}

# Manages the collection of instances, handling scaling and health checks
resource "aws_autoscaling_group" "compute_fleet" {
  # The unique name for this Auto Scaling Group
  name                = "ethereal-compute-fleet"
  # The list of VPC Subnet IDs where these nodes should be launched
  vpc_zone_identifier = var.subnet_ids
  # The absolute maximum number of nodes allowed in the fleet
  max_size            = var.max_size
  # The minimum number of nodes to keep running at all times
  min_size            = var.min_size
  # The target number of nodes the fleet should currently maintain
  desired_capacity    = var.desired_capacity

  # Configuration for using a mix of On-Demand and Spot instances
  mixed_instances_policy {
    instances_distribution {
      # The fixed number of On-Demand instances to always keep running
      on_demand_base_capacity                  = var.on_demand_base
      # Set to 0 to ensure every instance *above* the base capacity is a Spot instance
      on_demand_percentage_above_base_capacity = 0 
      # Selects the Spot pool with the most available capacity to lower interruption risk
      spot_allocation_strategy                 = "capacity-optimized" 
    }

    # Links the ASG to the Launch Template defined above
    launch_template {
      launch_template_specification {
        # Points to the ID of the hpc_node template
        launch_template_id = aws_launch_template.hpc_node.id
        # Always uses the most recently created version of the template
        version            = "$Latest"
      }
      
      # Flexibility for Spot availability: Primary instance choice
      override { instance_type = var.instance_type }
      # Flexibility for Spot availability: Backup instance choice if primary is unavailable
      override { instance_type = var.fallback_instance_type }
    }
  }

  # Ensures updates to the Launch Template are rolled out to the fleet automatically
  instance_refresh {
    # Replaces instances one by one (or in batches) rather than all at once
    strategy = "Rolling"
    preferences {
      # Keeps at least half the fleet running during a rolling update
      min_healthy_percentage = 50
    }
  }

  # Meta-argument to handle resource replacement order
  lifecycle {
    # Creates the new ASG/Resources before deleting the old ones to prevent downtime
    create_before_destroy = true
  }

  # Applies a 'Name' tag to every instance in the fleet
  tag {
    key                 = "Name"
    value               = "ethereal-hpc-worker"
    # Ensures the tag is actually applied to the EC2 instance, not just the ASG
    propagate_at_launch = true
  }
}
