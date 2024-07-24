/**
* This is the default network acl, but it is cannot detect changes with aws_network_acl_rule
* so we will set it up as a placeholder and use a secondary network acl
* Note: there are NO ingress or egress rules meaning it is completely locked down
*/
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.main.default_network_acl_id
  tags                   = {
    Name = "${var.name}-default-unused"
  }
}

/**
* Global Network ACL
* This ACL will block port 22 and 3389 but allow all others from both IPv4 and IPv6
*/
resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.main.id
  tags   = {
    Name = "${var.name}-used"
  }
  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

/**
* Ingress Dynamic
*/
resource "aws_network_acl_rule" "nacl_ipv4_ssh_allow" {
  count          = length(var.nacl_ipv4_allow_list)
  network_acl_id = aws_network_acl.main.id
  rule_number    = 100 + count.index
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
  cidr_block     = var.nacl_ipv4_allow_list[count.index]

  lifecycle {
    ignore_changes = [cidr_block]
  }
}
resource "aws_network_acl_rule" "nacl_ipv4_rdp_allow" {
  count          = length(var.nacl_ipv4_allow_list)
  network_acl_id = aws_network_acl.main.id
  rule_number    = 200 + count.index
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "allow"
  cidr_block     = var.nacl_ipv4_allow_list[count.index]

  lifecycle {
    ignore_changes = [cidr_block]
  }
}
/**
* Ingress Static
*/
resource "aws_network_acl_rule" "ingress_ssh_ipv4_deny" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 900
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
}
resource "aws_network_acl_rule" "ingress_ssh_ipv6_deny" {
  network_acl_id  = aws_network_acl.main.id
  rule_number     = 901
  protocol        = "tcp"
  from_port       = 22
  to_port         = 22
  rule_action     = "deny"
  ipv6_cidr_block = "::/0"
}
resource "aws_network_acl_rule" "ingress_rdp_ipv4_deny" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 902
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
}
resource "aws_network_acl_rule" "ingress_rdp_ipv6_deny" {
  network_acl_id  = aws_network_acl.main.id
  rule_number     = 903
  protocol        = "tcp"
  from_port       = 3389
  to_port         = 3389
  rule_action     = "deny"
  ipv6_cidr_block = "::/0"
}
resource "aws_network_acl_rule" "ingress_all_ipv4_allow" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 998
  protocol       = -1
  from_port      = 0
  to_port        = 0
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}
resource "aws_network_acl_rule" "ingress_all_ipv6_allow" {
  network_acl_id  = aws_network_acl.main.id
  rule_number     = 999
  protocol        = -1
  from_port       = 0
  to_port         = 0
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
}

/**
* Egress Dynamic
*/
resource "aws_network_acl_rule" "nacl_ipv4_ssh_deny_list" {
  count          = length(var.nacl_ipv4_allow_list)
  network_acl_id = aws_network_acl.main.id
  rule_number    = 100 + count.index
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
  egress         = true
  cidr_block     = var.nacl_ipv4_allow_list[count.index]

  lifecycle {
    ignore_changes = [cidr_block]
  }
}
resource "aws_network_acl_rule" "nacl_ipv4_rdp_deny_list" {
  count          = length(var.nacl_ipv4_allow_list)
  network_acl_id = aws_network_acl.main.id
  rule_number    = 200 + count.index
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "allow"
  egress         = true
  cidr_block     = var.nacl_ipv4_allow_list[count.index]

  lifecycle {
    ignore_changes = [cidr_block]
  }
}
/**
* Egress Static
*/
resource "aws_network_acl_rule" "egress_ssh_ipv4_deny" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 900
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  egress         = true
}
resource "aws_network_acl_rule" "egress_ssh_ipv6_deny" {
  network_acl_id  = aws_network_acl.main.id
  rule_number     = 901
  protocol        = "tcp"
  from_port       = 22
  to_port         = 22
  rule_action     = "deny"
  ipv6_cidr_block = "::/0"
  egress          = true
}
resource "aws_network_acl_rule" "egress_rdp_ipv4_deny" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 902
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  egress         = true
}
resource "aws_network_acl_rule" "egress_rdp_ipv6_deny" {
  network_acl_id  = aws_network_acl.main.id
  rule_number     = 903
  protocol        = "tcp"
  from_port       = 3389
  to_port         = 3389
  rule_action     = "deny"
  ipv6_cidr_block = "::/0"
  egress          = true
}
resource "aws_network_acl_rule" "egress_all_ipv4_allow" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 998
  protocol       = -1
  from_port      = 0
  to_port        = 0
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  egress         = true
}
resource "aws_network_acl_rule" "egress_all_ipv6_allow" {
  network_acl_id  = aws_network_acl.main.id
  rule_number     = 999
  protocol        = -1
  from_port       = 0
  to_port         = 0
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  egress          = true
}

/**
* Associate with Subnets
*/
resource "aws_network_acl_association" "public_acl" {
  count          = length(aws_subnet.public)
  network_acl_id = aws_network_acl.main.id
  subnet_id      = aws_subnet.public[count.index].id
}
resource "aws_network_acl_association" "private_acl" {
  count          = length(aws_subnet.private)
  network_acl_id = aws_network_acl.main.id
  subnet_id      = aws_subnet.private[count.index].id
}
