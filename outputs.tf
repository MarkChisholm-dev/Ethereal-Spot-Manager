output "asg_name" {
  value = aws_autoscaling_group.compute_fleet.name
}

output "launch_template_arn" {
  value = aws_launch_template.hpc_node.arn
}

output "fleet_id" {
  description = "The ID of the compute fleet for monitoring purposes"
  value       = aws_autoscaling_group.compute_fleet.id
}
