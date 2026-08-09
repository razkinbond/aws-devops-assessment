# 0. Dynamically fetch available zones in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# 1. VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.environment}-vpc" }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id     = aws_vpc.main.id

  depends_on = [aws_vpc.main]
  tags = { Name = "${var.environment}-igw" }
}

# 3. Public Subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  depends_on              = [aws_vpc.main]
  tags = { Name = "${var.environment}-public-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  
  depends_on              = [aws_vpc.main]
  tags = { Name = "${var.environment}-public-2" }
}

# 4. Private Subnets for Applications
resource "aws_subnet" "private_app_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  
  depends_on        = [aws_vpc.main]
  tags = { Name = "${var.environment}-private-app-1" }
}

resource "aws_subnet" "private_app_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  
  depends_on        = [aws_vpc.main]
  tags = { Name = "${var.environment}-private-app-2" }
}

# 5. Private Subnets for Database
resource "aws_subnet" "private_db_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  
  depends_on        = [aws_vpc.main]
  tags = { Name = "${var.environment}-private-db-1" }
}

resource "aws_subnet" "private_db_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  
  depends_on        = [aws_vpc.main]
  tags = { Name = "${var.environment}-private-db-2" }
}

# 6. Elastic IP & NAT Gateway
resource "aws_eip" "nat" {
  domain     = "vpc"
  
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_eip.nat, aws_subnet.public_1]

  tags = { Name = "${var.environment}-nat-gw" }
}

# 7. Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  depends_on = [aws_internet_gateway.gw]
  tags       = { Name = "${var.environment}-public-rt" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  depends_on = [aws_nat_gateway.nat]
  tags       = { Name = "${var.environment}-private-rt" }
}

# 8. Route Table Associations
resource "aws_route_table_association" "pub_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
  
  depends_on     = [aws_route_table.public, aws_subnet.public_1]
}

resource "aws_route_table_association" "pub_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
  
  depends_on     = [aws_route_table.public, aws_subnet.public_2]
}

resource "aws_route_table_association" "priv_app_1" {
  subnet_id      = aws_subnet.private_app_1.id
  route_table_id = aws_route_table.private.id
  
  depends_on     = [aws_route_table.private, aws_subnet.private_app_1]
}

resource "aws_route_table_association" "priv_app_2" {
  subnet_id      = aws_subnet.private_app_2.id
  route_table_id = aws_route_table.private.id
  
  depends_on     = [aws_route_table.private, aws_subnet.private_app_2]
}