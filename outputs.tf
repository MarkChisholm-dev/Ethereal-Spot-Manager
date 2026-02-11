# Returns the human-readable name of the Auto Scaling Group
# Useful for CLI commands and targeting the fleet in custom scripts
output "asg_name" {
  value = aws_autoscaling_group.compute_fleet.name
}

# Returns the Amazon Resource Name (ARN) of the launch template
# This is the unique global identifier used for IAM policies or cross-account sharing
output "launch_template_arn" {
  value = aws_launch_template.hpc_node.arn
}

# Provides the unique ID of the Auto Scaling Group
# Specifically designated for integration with monitoring tools like CloudWatch or Datadog
output "fleet_id" {
  description = "The ID of the compute fleet for monitoring purposes"
  value       = aws_autoscaling_group.compute_fleet.id
}
