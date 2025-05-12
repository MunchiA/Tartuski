output "web_access_url" {
  value       = "http://${aws_lb.alb.dns_name}"
  description = "La URL para acceder a la aplicación web"
}
output "aurora_endpoint" {
  description = "Endpoint de la base de datos Aurora"
  value       = aws_rds_cluster.aurora_sql_cluster_tartuski.endpoint
}
output "s3_bucket_name" {
  description = "Nombre del bucket S3 de respaldo"
  value       = aws_s3_bucket.source.id
}
