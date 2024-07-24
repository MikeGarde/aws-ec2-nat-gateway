/**
* Elastic IP for NAT Gateway
*/
resource "aws_eip" "nat_ip" {
  count  = var.match_nat_gateway_count ? var.public_subnet_count : 1
  domain = "vpc"
  tags   = {
    Name = "NAT Gateway EIP - ${count.index + 1}"
  }
}
resource "aws_eip_association" "nat_eip_assoc" {
  count         = var.match_nat_gateway_count ? var.public_subnet_count : 1
  instance_id   = aws_instance.nat_gw[count.index].id
  allocation_id = aws_eip.nat_ip[count.index].id
}
output "nat_ip" {
  value = aws_eip.nat_ip[*].public_ip
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
  count         = var.match_nat_gateway_count ? var.public_subnet_count : 1
  ami           = data.aws_ami.nat.id
  instance_type = "t4g.nano"
  hibernation   = false
  key_name      = var.nat_key_name
  network_interface {
    network_interface_id = aws_network_interface.nat_gw[count.index].id
    device_index         = 0
  }
  root_block_device {
    delete_on_termination = true
    volume_type           = "gp3"
    volume_size           = 8
    throughput            = 125
    iops                  = 3000
    encrypted             = var.encrypt_at_rest
    kms_key_id            = var.encrypt_at_rest ? aws_kms_key.default[0].arn : ""
  }
  tags = {
    Name = "NAT ${aws_vpc.main.tags.Name} ${substr(aws_subnet.public[count.index].availability_zone, -2, 2)}"
  }
  lifecycle {
    ignore_changes = [ami]
  }
}
resource "aws_network_interface" "nat_gw" {
  count           = var.match_nat_gateway_count ? var.public_subnet_count : 1
  subnet_id       = aws_subnet.public[count.index].id
  security_groups = [
    aws_security_group.nat.id,
    aws_security_group.ssh.id
  ]
  source_dest_check = false
  tags = {
    Name = "NAT ${aws_vpc.main.tags.Name} ${substr(aws_subnet.public[count.index].availability_zone, -2, 2)}"
  }
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
