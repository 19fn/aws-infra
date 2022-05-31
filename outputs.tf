output "bastion_public_ip" {
  description = "The public IP address assigned to the instance."
  value       = try(aws_instance.bastion-host.public_ip)
}

output "frontend_public_ip" {
  description = "The public IP address assigned to the instance."
  value       = try(aws_instance.frontend.public_ip)
}

output "backend_private_ip" {
  description = "The private IP address assigned to the instance."
  value       = try(aws_instance.backend.private_ip)
}

output "bastion_instance_type" {
  description = "Instance Type"
  value = try(aws_instance.bastion-host.instance_type)
}

output "frontend_instance_type" {
  description = "Instance Type"
  value = try(aws_instance.frontend.instance_type)
}

output "backend_instance_type" {
  description = "Instance Type"
  value = try(aws_instance.backend.instance_type)
}