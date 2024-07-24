# Test EC2 Instance
data "aws_ami" "test" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
resource "aws_instance" "test_instance" {
  count                  = var.launch_test_instance ? 1 : 0
  ami                    = data.aws_ami.test.id
  instance_type          = "t3.nano"
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = var.nat_key_name

  tags = {
    Name = "Test Instance"
  }
}
