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

/**
* Elastic IP for NAT Gateway
*/
resource "aws_eip" "nat_ip" {
  tags = {
    Name = "NAT Gateway EIP"
  }
  # Minimize the time the EIP will be unused
  depends_on = [aws_subnet.public[0]]
}
resource "aws_eip_association" "nat_eip_assoc" {
  instance_id   = aws_instance.nat_gw.id
  allocation_id = aws_eip.nat_ip.id
}
output "nat_ip" {
  value = aws_eip.nat_ip.public_ip
}

/**
* NAT Gateway
*/
data "aws_ami" "nat" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["nat-gateway-al2023-*"]
  }
  filter {
    name   = "architecture"
    values = [var.nat_gateway_arch]
  }
}
resource "aws_instance" "nat_gw" {
  ami           = data.aws_ami.nat.id
  instance_type = "t4g.nano"
  hibernation   = false
  key_name      = var.nat_key_name
  network_interface {
    network_interface_id = aws_network_interface.nat_gw.id
    device_index         = 0
  }
  tags = {
    Name = "NAT Gateway"
  }
  # lifecycle {
  #   ignore_changes = [ami]
  # }
}
resource "aws_network_interface" "nat_gw" {
  subnet_id       = aws_subnet.public[0].id
  security_groups = [
    aws_security_group.nat.id,
    aws_security_group.ssh.id
  ]

  source_dest_check = false
}

/**
* NAT Gateway Security Groups
*/
resource "aws_security_group" "nat" {
  vpc_id      = aws_vpc.main.id
  name        = "nat"
  description = "Allow private network traffic to NAT Gateway"

  tags = {
    Name = "nat"
  }
}
// Ingress Rules for NAT Gateway
resource "aws_vpc_security_group_ingress_rule" "nat_ingress_icmp_ipv4" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}
resource "aws_vpc_security_group_ingress_rule" "nat_ingress_icmp_ipv6" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv6         = aws_vpc.main.ipv6_cidr_block
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}
// DELETE THESE
# resource "aws_vpc_security_group_ingress_rule" "nat_ingress_ssh_ipv4" {
#   security_group_id = aws_security_group.nat.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "tcp"
#   from_port         = 22
#   to_port           = 22
# }
# resource "aws_vpc_security_group_ingress_rule" "nat_ingress_ssh_ipv6" {
#   security_group_id = aws_security_group.nat.id
#   cidr_ipv6         = "::/0"
#   ip_protocol       = "tcp"
#   from_port         = 22
#   to_port           = 22
# }
//
resource "aws_vpc_security_group_ingress_rule" "nat_ingress_http_ipv4" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "nat_ingress_http_ipv6" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv6         = aws_vpc.main.ipv6_cidr_block
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "nat_ingress_https_ipv4" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
resource "aws_vpc_security_group_ingress_rule" "nat_ingress_https_ipv6" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv6         = aws_vpc.main.ipv6_cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
// Egress Rules for NAT Gateway
resource "aws_vpc_security_group_egress_rule" "nat_egress_icmp_ipv4" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}
resource "aws_vpc_security_group_egress_rule" "nat_egress_http_ipv4" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
resource "aws_vpc_security_group_egress_rule" "nat_egress_https_ipv4" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
resource "aws_vpc_security_group_egress_rule" "nat_egress_ssh_ipv4" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}
resource "aws_vpc_security_group_egress_rule" "nat_egress_icmp_ipv6" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}
resource "aws_vpc_security_group_egress_rule" "nat_egress_http_ipv6" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
resource "aws_vpc_security_group_egress_rule" "nat_egress_https_ipv6" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
resource "aws_vpc_security_group_egress_rule" "nat_egress_ssh_ipv6" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv6         = aws_vpc.main.ipv6_cidr_block
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

/**
* SSH Security Group
*/
resource "aws_security_group" "ssh" {
  vpc_id      = aws_vpc.main.id
  name        = "ssh"
  description = "Allow SSH traffic"

  tags = {
    Name = "ssh"
  }
}
resource "aws_vpc_security_group_ingress_rule" "ssh_ingress_ssh_ipv4" {
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = "internal"
}
resource "aws_vpc_security_group_ingress_rule" "ssh_ingress_admin" {
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4         = "${var.sg_ssh_admin_ipv4}/32"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = var.sg_ssh_admin_name
}
resource "aws_vpc_security_group_ingress_rule" "ssh_ingress_ssh_dynamic" {
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 1025
  to_port           = 65535
  description       = "Dynamic"
}

/**
* EC2 Instance Connect
*/
resource "aws_ec2_instance_connect_endpoint" "ec2_connect" {
  subnet_id = aws_subnet.public[0].id
  tags      = {
    Name = "ec2-connect"
  }
}
resource "aws_vpc_security_group_ingress_rule" "ssh_ingress_ssh_ec2_connect" {
  count             = length(var.sg_ssh_ec2_connect_ips)
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4         = var.sg_ssh_ec2_connect_ips[count.index]
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = "EC2 Connect"
}
resource "aws_vpc_security_group_ingress_rule" "ssh_ingress_ssh_ec2_connect_web" {
  count             = length(var.sg_ssh_ec2_connect_ips)
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4         = var.sg_ssh_ec2_connect_ips[count.index]
  ip_protocol       = "tcp"
  from_port         = 49152
  to_port           = 65535
  description       = "EC2 Connect Web"
}
resource "aws_vpc_security_group_egress_rule" "ssh_egress_all_ipv4" {
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
}
resource "aws_vpc_security_group_egress_rule" "ssh_egress_all_ipv6" {
  security_group_id = aws_security_group.ssh.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
}

# Test EC2 Instance
resource "aws_instance" "test_instance" {
  ami             = "ami-08a0d1e16fc3f61ea"
  instance_type   = "t3.nano"
  subnet_id       = aws_subnet.private[0].id
  security_groups = [aws_security_group.ssh.id]
  key_name        = var.nat_key_name

  tags = {
    Name = "Test Instance"
  }
}
