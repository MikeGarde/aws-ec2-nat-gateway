packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "our_timestamp" {
  type    = string
  default = "{{isotime `2006-01-02 03:04:05` | replace_all \"-\" \".\" | replace_all \":\" \"\" | replace \" \" \"-\" 1 }}"
}
variable "aws_region" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "subnet_id" {
  type = string
}

source "amazon-ebs" "x86" {
  ami_name        = "nat-gateway-al2023-${var.our_timestamp}-x86_64"
  ami_description = "NAT Gateway x86_64 - {{timestamp}}"
  tags            = {
    application = "support"
    stage       = "dev"
    owner       = "networking"
  }
  instance_type = "t3.micro"
  region        = "${var.aws_region}"
  vpc_id        = "${var.vpc_id}"
  subnet_id     = "${var.subnet_id}"
  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = "8"
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
  }
  source_ami_filter {
    filters = {
      name                = "al2023-ami-minimal-2023.*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture        = "x86_64"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
}

source "amazon-ebs" "arm64" {
  ami_name        = "nat-gateway-al2023-${var.our_timestamp}-arm64"
  ami_description = "NAT Gateway arm64 - {{timestamp}}"
  tags            = {
    application = "support"
    stage       = "dev"
    owner       = "networking"
  }
  instance_type = "t4g.micro"
  region        = "${var.aws_region}"
  vpc_id        = "${var.vpc_id}"
  subnet_id     = "${var.subnet_id}"
  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = "8"
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
  }
  source_ami_filter {
    filters = {
      name                = "al2023-ami-minimal-2023.*-arm64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture        = "arm64"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
}

build {
  name    = "nat-gateway"
  sources = [
    "source.amazon-ebs.x86",
    "source.amazon-ebs.arm64",
  ]

  # Transfer SELinux module to the machine
  provisioner "file" {
    source      = "./ssh_module.te"
    destination = "/tmp/ssh_module.te"
  }

  # Setup Instance to be a NAT Gateway
  provisioner "shell" {
    script = "./setup.sh"
  }

  # Unnecessary but nice to have
  provisioner "shell" {
    inline = [
      # Ohh so pretty
      "sudo yum install htop -y",
    ]
  }
}
