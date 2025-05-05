provider "aws" {
  region = var.aws_region_main
}

# Definición de la VPC
resource "aws_vpc" "tartuski_vpc" {
  cidr_block = "10.0.0.0/16"  # Ajusta el CIDR si es necesario
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
