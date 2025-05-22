variable "private_key_path" {
  description = "Ruta clave privada"
  type        = string
}

variable "aws_region_main" {
  default = "us-east-1"
}

# Variable para el dominio
variable "domain_name" {
  type        = string
  description = "Nombre del dominio para DNSExit"
  default     = "tartuski.linkpc.net"
}
