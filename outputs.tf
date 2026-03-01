# Returns the human-readable name of the Auto Scaling Group
# Useful for CLI commands and targeting the fleet in custom scripts
output "asg_name" {
  value       = aws_autoscaling_group.compute_fleet.name
  description = "Name of the Auto Scaling Group"
}

# Returns the Amazon Resource Name (ARN) of the launch template
# This is the unique global identifier used for IAM policies or cross-account sharing
output "launch_template_arn" {
  value       = aws_launch_template.hpc_node.arn
  description = "ARN of the launch template"
}

# Provides the unique ID of the Auto Scaling Group
# Specifically designated for integration with monitoring tools like CloudWatch or Datadog
output "fleet_id" {
  description = "The ID of the compute fleet for monitoring purposes"
  value       = aws_autoscaling_group.compute_fleet.id
}

# Launch template ID for reference in other resources
output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.hpc_node.id
}

# Latest version of the launch template
output "launch_template_latest_version" {
  description = "Latest version number of the launch template"
  value       = aws_launch_template.hpc_node.latest_version
}

# Security group ID used by the fleet
output "security_group_id" {
  description = "Security group ID attached to instances"
  value       = var.security_group_id
}

# Subnet IDs where instances are deployed
output "subnet_ids" {
  description = "List of subnet IDs where instances are deployed"
  value       = var.subnet_ids
}

# Auto scaling policy ARN (if enabled)
output "cpu_scaling_policy_arn" {
  description = "ARN of the CPU-based auto scaling policy"
  value       = var.enable_cpu_scaling ? aws_autoscaling_policy.cpu_target_tracking[0].arn : null
}

# Current capacity configuration
output "capacity_config" {
  description = "Current capacity configuration of the fleet"
  value = {
    min_size         = aws_autoscaling_group.compute_fleet.min_size
    max_size         = aws_autoscaling_group.compute_fleet.max_size
    desired_capacity = aws_autoscaling_group.compute_fleet.desired_capacity
  }
}
