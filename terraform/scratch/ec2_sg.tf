resource "aws_security_group" "ssh_admin" {
  vpc_id      = aws_vpc.main.id
  name        = "ssh_admin"
  description = "Allow ssh from admin users"

  tags = {
    Name = "ssh_admin"
  }
}
resource "aws_vpc_security_group_ingress_rule" "ssh_admin_ingress_ssh_ipv4" {
  security_group_id = aws_security_group.nat.id
  description       = var.sg_ssh_admin_name
  cidr_ipv4         = "${var.sg_ssh_admin_ipv4}/32"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  lifecycle {
    ignore_changes = [cidr_ipv4]
  }
}
