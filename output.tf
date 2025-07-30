output "frontend_public_ip" {
  description = "Public IP of the FRONTEND instance"
  value       = aws_instance.frontend.public_ip
}

output "backend_private_ip" {
  description = "Private IP of the BACKEND instance"
  value       = aws_instance.backend.private_ip
}

output "frontend_url" {
  description = "URL to access the frontend app"
  value       = "http://${aws_instance.frontend.public_ip}:80"
}
