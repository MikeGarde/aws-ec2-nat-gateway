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
   lifecycle {
     ignore_changes = [ami]
   }
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
