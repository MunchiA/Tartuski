provider "aws" {
  region = var.aws_region_main
}

# Definición de la VPC
resource "aws_vpc" "tartuski_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Tartuski VPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.tartuski_vpc.id
  tags = {
    Name = "Internet Gateway"
  }
}

# Subredes públicas para NAT Gateways
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

# Subredes privadas para aplicaciones web
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

# Subredes privadas para bases de datos
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

# Elastic IPs para los NAT Gateways
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

# NAT Gateways
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

# Tabla de rutas para subredes públicas
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

# Asociaciones para subredes públicas
resource "aws_route_table_association" "public_a_association" {
  subnet_id      = aws_subnet.public_nat_subnet_1a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_b_association" {
  subnet_id      = aws_subnet.public_nat_subnet_1b.id
  route_table_id = aws_route_table.public_route_table.id
}

# Tablas de rutas para subredes privadas
# Zona A
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

# Zona B
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

# Asociaciones de tablas de rutas para subredes privadas
# Subredes WEB
resource "aws_route_table_association" "private_web_a_association" {
  subnet_id      = aws_subnet.private_web_subnet_1a.id
  route_table_id = aws_route_table.private_route_table_a.id
}

resource "aws_route_table_association" "private_web_b_association" {
  subnet_id      = aws_subnet.private_web_subnet_1b.id
  route_table_id = aws_route_table.private_route_table_b.id
}

# Subredes DB
resource "aws_route_table_association" "private_db_a_association" {
  subnet_id      = aws_subnet.private_DB_subnet_1a.id
  route_table_id = aws_route_table.private_route_table_a.id
}

resource "aws_route_table_association" "private_db_b_association" {
  subnet_id      = aws_subnet.private_DB_subnet_1b.id
  route_table_id = aws_route_table.private_route_table_b.id
}

# Grupo de seguridad para el ALB (permite tráfico público en puertos 80 y 443)
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

# Grupo de seguridad para las instancias web (permite tráfico del ALB y SSH desde el bastión)
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

# Balanceador de carga (actualizado para usar el grupo de seguridad del ALB)
resource "aws_lb" "alb" {
  name               = "tartuski-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_subnet.public_nat_subnet_1a.id,
    aws_subnet.public_nat_subnet_1b.id
  ]

  tags = {
    Name = "Tartuski ALB"
  }
}

# Grupo de destino para el balanceador de carga
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

# Listener para el balanceador de carga
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Plantilla de lanzamiento para las instancias del grupo de autoescalado
resource "aws_launch_template" "web_launch_template" {
  name_prefix   = "tartuski-web-"
  image_id      = "ami-0fc5d935ebf8bc3bc" # AMI usada en la instancia original
  instance_type = "t3.micro"
  key_name      = "vockey"
  user_data     = filebase64("init.sh") # Script de inicialización codificado en base64

  network_interfaces {
    associate_public_ip_address = false # No asignar IPs públicas (subredes privadas)
    security_groups             = [aws_security_group.web_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Tartuski Web Instance"
    }
  }
}

# Grupo de autoescalado para gestionar las instancias web
resource "aws_autoscaling_group" "web_asg" {
  name                = "tartuski-web-asg"
  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = "$Latest" # Usa la versión más reciente de la plantilla
  }
  min_size            = 1  # Mínimo 1 instancia corriendo
  max_size            = 3  # Máximo 3 instancias
  desired_capacity    = 1  # Capacidad inicial
  vpc_zone_identifier = [aws_subnet.private_web_subnet_1a.id, aws_subnet.private_web_subnet_1b.id] # Subredes privadas
  target_group_arns   = [aws_lb_target_group.tg.arn] # Asociar al grupo de destino del ALB
}

# Política de escalado hacia arriba cuando la CPU >= 70%
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1  # Aumentar en 1 instancia
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300 # 5 minutos de enfriamiento
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

# Alarma de CloudWatch para disparar el escalado hacia arriba
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2  # Evaluar durante 2 períodos
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300 # Período de 5 minutos
  statistic           = "Average"
  threshold           = 70  # Umbral del 70%
  alarm_description   = "Dispara cuando la CPU promedio supera el 70% durante 10 minutos"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

# Política de escalado hacia abajo cuando la CPU <= 30% (opcional para estabilidad)
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1 # Reducir en 1 instancia
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300 # 5 minutos de enfriamiento
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

# Alarma de CloudWatch para disparar el escalado hacia abajo
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu-usage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30  # Umbral del 30%
  alarm_description   = "Dispara cuando la CPU promedio cae por debajo del 30% durante 10 minutos"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}

# Grupo de seguridad para el bastión
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

# Elastic IP para el bastión
resource "aws_eip" "bastion_eip" {
  domain = "vpc"
  tags = {
    Name = "Bastion_Tartuski EIP"
  }
}

# Instancia bastión
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

# Asociación del Elastic IP al bastión
resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.bastion_host.id
  allocation_id = aws_eip.bastion_eip.id
}
