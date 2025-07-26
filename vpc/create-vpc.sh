output "frontend_public_ip" {
  description = "Public IP of the frontend instance"
  value       = aws_instance.frontend.public_ip
}

output "frontend_public_dns" {
  description = "Public DNS of the frontend instance"
  value       = aws_instance.frontend.public_dns
}

output "backend_private_ip" {
  description = "Private IP of the backend instance"
  value       = aws_instance.backend.private_ip
}
