output "web_access_url" {
  value       = "http://${aws_lb.alb.dns_name}"
  description = "La URL para acceder a la aplicación web"
}