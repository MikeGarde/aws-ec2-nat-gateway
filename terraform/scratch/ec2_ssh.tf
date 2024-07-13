/**
* EC2 Instance Connect
*/
resource "aws_ec2_instance_connect_endpoint" "ec2_connect" {
  count     = var.enable_ec2_connect ? 1 : 0
  subnet_id = aws_subnet.public[0].id
  tags      = {
    Name = "ec2-connect"
  }
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
resource "aws_vpc_security_group_ingress_rule" "ssh_ingress_ssh_dynamic" {
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 1025
  to_port           = 65535
  description       = "Dynamic"
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
resource "aws_vpc_security_group_ingress_rule" "ssh_admin_ingress_ssh_ipv4" {
  security_group_id = aws_security_group.ssh.id
  description       = var.sg_ssh_admin_name
  cidr_ipv4         = "${var.sg_ssh_admin_ipv4}/32"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  lifecycle {
    ignore_changes = [cidr_ipv4]
  }
}
