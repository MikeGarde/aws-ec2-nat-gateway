/**
* VPC
*/
resource "aws_vpc" "main" {
  cidr_block                       = var.vpc_cidr
  instance_tenancy                 = "default"
  enable_dns_support               = var.enable_dns_support
  enable_dns_hostnames             = var.enable_dns_hostnames
  assign_generated_ipv6_cidr_block = true
  tags                             = {
    Name = "main"
  }
}

/**
* Internet Gateway for Public Subnets
*/
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = {
    Name = "${aws_vpc.main.tags.Name}-igw"
  }
}

/**
* Subnets
*/
resource "aws_subnet" "public" {
  count                           = var.public_subnet_count
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = var.public_subnet_cidr_blocks[count.index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index)
  availability_zone               = "${var.region}${element(var.subnet_azs, count.index)}"
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true
  depends_on                      = [aws_internet_gateway.igw]
  tags                            = {
    Name = "public-${substr(var.region, -1, 1)}${element(var.subnet_azs, count.index)}"
  }
}
resource "aws_subnet" "private" {
  count                   = var.private_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr_blocks[count.index]
  availability_zone       = "${var.region}${element(var.subnet_azs, count.index)}"
  map_public_ip_on_launch = false
  tags                    = {
    Name = "private-${substr(var.region, -1, 1)}${element(var.subnet_azs, count.index)}"
  }
}

/**
* Route Tables
*/
resource "aws_default_route_table" "public_rt" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }
  route {
    ipv6_cidr_block = aws_vpc.main.ipv6_cidr_block
    gateway_id      = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public"
  }
}
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }
  route {
    ipv6_cidr_block = aws_vpc.main.ipv6_cidr_block
    gateway_id      = "local"
  }
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat_gw.primary_network_interface_id
  }
  route {
    ipv6_cidr_block      = "::/0"
    network_interface_id = aws_instance.nat_gw.primary_network_interface_id
  }
  tags = {
    Name = "private"
  }
}
resource "aws_route_table_association" "public_rt_association" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_vpc.main.default_route_table_id
}
resource "aws_route_table_association" "private_rt_association" {
  count          = var.private_subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# Test EC2 Instance
#resource "aws_instance" "test_instance" {
#  ami             = "ami-08a0d1e16fc3f61ea"
#  instance_type   = "t3.nano"
#  subnet_id       = aws_subnet.private[0].id
#  security_groups = [aws_security_group.ssh.id]
#  key_name        = var.nat_key_name
#
#  tags = {
#    Name = "Test Instance"
#  }
#}
