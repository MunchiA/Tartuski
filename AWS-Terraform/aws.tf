# ==============================================
# PROVEEDOR AWS
# ==============================================
provider "aws" {
  region = var.aws_region_main
}

# ==============================================
# VPC Y REDES
# ==============================================
resource "aws_vpc" "tartuski_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Tartuski VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.tartuski_vpc.id
  tags = {
    Name = "Internet Gateway"
  }
}

# Subredes públicas para NAT Gateways en zonas A y B
resource "aws_subnet" "public_nat_subnet_1a" {
  vpc_id                  = aws_vpc.tartuski_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region_main}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public NAT Zona A"
  }
}

resource "aws_subnet" "public_nat_subnet_1b" {
  vpc_id                  = aws_vpc.tartuski_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region_main}b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public NAT Zona B"
  }
}

# Subredes privadas para aplicaciones web en zonas A y B
resource "aws_subnet" "private_web_subnet_1a" {
  vpc_id                  = aws_vpc.tartuski_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "${var.aws_region_main}a"
  map_public_ip_on_launch = false
  tags = {
    Name = "Private WEB Zona A"
  }
}

resource "aws_subnet" "private_web_subnet_1b" {
  vpc_id                  = aws_vpc.tartuski_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "${var.aws_region_main}b"
  map_public_ip_on_launch = false
  tags = {
    Name = "Private WEB Zona B"
  }
}

# Subredes privadas para bases de datos en zonas A y B
resource "aws_subnet" "private_DB_subnet_1a" {
  vpc_id                  = aws_vpc.tartuski_vpc.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "${var.aws_region_main}a"
  map_public_ip_on_launch = false
  tags = {
    Name = "Private DB Zona A"
  }
}

resource "aws_subnet" "private_DB_subnet_1b" {
  vpc_id                  = aws_vpc.tartuski_vpc.id
  cidr_block              = "10.0.6.0/24"
  availability_zone       = "${var.aws_region_main}b"
  map_public_ip_on_launch = false
  tags = {
    Name = "Private DB Zona B"
  }
}

# IPs estáticas para los NAT Gateways
resource "aws_eip" "nat_eip_a" {
  domain = "vpc"
  tags = {
    Name = "NAT EIP Zona A"
  }
}

resource "aws_eip" "nat_eip_b" {
  domain = "vpc"
  tags = {
    Name = "NAT EIP Zona B"
  }
}

# NAT Gateways para permitir salida a Internet desde subredes privadas
resource "aws_nat_gateway" "nat_gateway_a" {
  allocation_id = aws_eip.nat_eip_a.id
  subnet_id     = aws_subnet.public_nat_subnet_1a.id
  tags = {
    Name = "NAT Gateway Zona A"
  }
}

resource "aws_nat_gateway" "nat_gateway_b" {
  allocation_id = aws_eip.nat_eip_b.id
  subnet_id     = aws_subnet.public_nat_subnet_1b.id
  tags = {
    Name = "NAT Gateway Zona B"
  }
}

# Tabla de rutas públicas hacia Internet Gateway
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.tartuski_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public Route Table"
  }
}

# Asociaciones de subredes públicas a la tabla de rutas
resource "aws_route_table_association" "public_a_association" {
  subnet_id      = aws_subnet.public_nat_subnet_1a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_b_association" {
  subnet_id      = aws_subnet.public_nat_subnet_1b.id
  route_table_id = aws_route_table.public_route_table.id
}

# Tablas de rutas privadas hacia NAT Gateways en zonas A y B
resource "aws_route_table" "private_route_table_a" {
  vpc_id = aws_vpc.tartuski_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_a.id
  }
  tags = {
    Name = "Private Route Table Zona A"
  }
}

resource "aws_route_table" "private_route_table_b" {
  vpc_id = aws_vpc.tartuski_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_b.id
  }
  tags = {
    Name = "Private Route Table Zona B"
  }
}

# Asociaciones de subredes privadas (web y DB) a tablas de rutas
resource "aws_route_table_association" "private_web_a_association" {
  subnet_id      = aws_subnet.private_web_subnet_1a.id
  route_table_id = aws_route_table.private_route_table_a.id
}

resource "aws_route_table_association" "private_web_b_association" {
  subnet_id      = aws_subnet.private_web_subnet_1b.id
  route_table_id = aws_route_table.private_route_table_b.id
}

resource "aws_route_table_association" "private_db_a_association" {
  subnet_id      = aws_subnet.private_DB_subnet_1a.id
  route_table_id = aws_route_table.private_route_table_a.id
}

resource "aws_route_table_association" "private_db_b_association" {
  subnet_id      = aws_subnet.private_DB_subnet_1b.id
  route_table_id = aws_route_table.private_route_table_b.id
}

# ==============================================
# GRUPOS DE SEGURIDAD
# ==============================================
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Permite HTTP y HTTPS desde Internet hacia el ALB"
  vpc_id      = aws_vpc.tartuski_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ALB SG"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Permite HTTP desde el ALB y SSH desde el bastion a las instancias web"
  vpc_id      = aws_vpc.tartuski_vpc.id
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Web SG"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  vpc_id      = aws_vpc.tartuski_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Bastion Host SG"
  }
}

resource "aws_security_group" "db_tier_sg" {
  name        = "db_tier_sg"
  description = "Allow SQL server inbound traffic"
  vpc_id      = aws_vpc.tartuski_vpc.id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
}

# ==============================================
# BALANCEADOR DE CARGA (ALB)
# ==============================================
resource "aws_lb" "alb" {
  name               = "tartuski-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_nat_subnet_1a.id, aws_subnet.public_nat_subnet_1b.id]
  tags = {
    Name = "Tartuski ALB"
  }
}

resource "aws_lb_target_group" "tg" {
  name        = "tartuski-tg"
  port        = 8000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.tartuski_vpc.id
  health_check {
    path     = "/"
    protocol = "HTTP"
    matcher  = "200"
    port     = "8000"
  }
}

resource "aws_acm_certificate" "cert" {
  private_key       = var.private_key
  certificate_body  = var.certificate_body
  certificate_chain = var.certificate_chain
  tags = {
    Name = "Tartuski Certificate"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ==============================================
# AUTOESCALADO
# ==============================================
resource "aws_launch_template" "web_launch_template" {
  name_prefix   = "tartuski-web-"
  image_id      = "ami-05b10e08d247fb927"
  instance_type = "t3.micro"
  key_name      = "vockey"
  user_data = base64encode(templatefile("init.sh", { db_host = aws_rds_cluster.aurora_sql_cluster_tartuski.endpoint }))
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.web_sg.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Tartuski Web Instance"
    }
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name                = "tartuski-web-asg"
  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = "$Latest"
  }
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  vpc_zone_identifier = [aws_subnet.private_web_subnet_1a.id, aws_subnet.private_web_subnet_1b.id]
  target_group_arns   = [aws_lb_target_group.tg.arn]
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Dispara cuando la CPU promedio supera el 70% durante 10 minutos"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu-usage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "Dispara cuando la CPU promedio cae por debajo del 30% durante 10 minutos"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}

# ==============================================
# INSTANCIA BASTIÓN
# ==============================================
resource "aws_instance" "bastion_host" {
  ami                    = "ami-05b10e08d247fb927"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_nat_subnet_1a.id
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  tags = {
    Name = "Bastion_Tartuski"
  }
}

resource "aws_eip" "bastion_eip" {
  domain = "vpc"
  tags = {
    Name = "Bastion_Tartuski EIP"
  }
}

resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.bastion_host.id
  allocation_id = aws_eip.bastion_eip.id
}

# ==============================================
# BASE DE DATOS AURORA
# ==============================================
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [aws_subnet.private_DB_subnet_1a.id, aws_subnet.private_DB_subnet_1b.id]
  tags = {
    Name = "DB subnet group"
  }
}

resource "aws_rds_cluster" "aurora_sql_cluster_tartuski" {
  cluster_identifier      = "db-cluster-tartuski"
  availability_zones      = ["${var.aws_region_main}a", "${var.aws_region_main}b"]
  database_name           = "aurora_sql_tartuski"
  master_username         = "admin"
  master_password         = "tartuski"
  engine                  = "aurora-mysql"
  vpc_security_group_ids  = [aws_security_group.db_tier_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot     = true
  apply_immediately       = true
  tags = {
    Name = "Aurora SQL Cluster Tartuski"
  }
}

resource "aws_rds_cluster_instance" "aurora_sql_instance" {
  cluster_identifier  = aws_rds_cluster.aurora_sql_cluster_tartuski.id
  instance_class      = "db.t3.medium"
  publicly_accessible = false
  engine              = aws_rds_cluster.aurora_sql_cluster_tartuski.engine
  engine_version      = aws_rds_cluster.aurora_sql_cluster_tartuski.engine_version
  availability_zone   = "${var.aws_region_main}a"
  tags = {
    Name = "Aurora SQL Instance Primary ZONA A"
  }
}

resource "aws_rds_cluster_instance" "aurora_sql_replica" {
  cluster_identifier  = aws_rds_cluster.aurora_sql_cluster_tartuski.id
  instance_class      = "db.t3.medium"
  publicly_accessible = false
  engine              = aws_rds_cluster.aurora_sql_cluster_tartuski.engine
  engine_version      = aws_rds_cluster.aurora_sql_cluster_tartuski.engine_version
  availability_zone   = "${var.aws_region_main}b"
  tags = {
    Name = "Aurora SQL Instance Replica ZONA B"
  }
}

# ====================================
# S3 Creation
# ====================================

# Retrieve the existing IAM role for S3 replication
data "aws_iam_role" "replication_role" {
  name = "LabRole"
}

# Create the source S3 bucket for backups
resource "aws_s3_bucket" "source" {
  bucket = "tartuski-backup-202527"
}

# Enable versioning for the source bucket
resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Create the destination S3 bucket for replication
resource "aws_s3_bucket" "destination" {
  bucket = "tartuski-backup-replica-202527"
}

# Enable versioning for the destination bucket
resource "aws_s3_bucket_versioning" "destination" {
  bucket = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure replication from source to destination bucket
resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.source.id
  role   = data.aws_iam_role.replication_role.arn

  rule {
    status = "Enabled"

    destination {
      bucket = aws_s3_bucket.destination.arn
    }
  }

  # Asegura que el versionado del bucket de destino esté habilitado antes de la replicación
  depends_on = [aws_s3_bucket_versioning.destination]
}

# Set up lifecycle rules for the destination bucket
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_config" {
  bucket = aws_s3_bucket.destination.id

  # Rule to move objects to Standard-IA after 30 days
  rule {
    id     = "transition-to-standard-ia"
    status = "Enabled"
    filter { prefix = "" }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  # Rule to move objects to S3 Glacier after 6 months (180 days)
  rule {
    id     = "transition-to-glacier"
    status = "Enabled"
    filter { prefix = "" }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }
  }
}
