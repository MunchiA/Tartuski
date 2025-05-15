output "alb_dns_name" {
  value = aws_lb.alb.dns_name
  description = "DNS del Load Balancer para tartuski.cat"
}
# Output para el endpoint de la base de datos Aurora
output "aurora_endpoint" {
  value       = aws_rds_cluster.aurora_sql_cluster_tartuski.endpoint
  description = "Endpoint del clúster Aurora para conexiones de escritura"
}
# Output para el nombre de dominio del bucket S3 source
output "s3_bucket_domain_name" {
  value       = aws_s3_bucket.source.bucket_domain_name
  description = "Nombre de dominio del bucket S3 fuente (tartuski-backup-202527)"
}
