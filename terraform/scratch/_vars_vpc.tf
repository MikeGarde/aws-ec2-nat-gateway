// Common
variable "region" {
  type        = string
  description = "Region of the VPC"
  default     = "us-east-1"
}
variable "env" {
  type        = string
  description = "Environment"
  default     = "dev"
}

// VPC
variable "name" {
  type        = string
  description = "Name of the VPC"
  default     = "main"
}
variable "enable_dns_support" {
  type        = bool
  description = "Enable DNS support"
  default     = true
}
variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames"
  default     = true
}
variable "domain" {
  type        = string
  description = "Set the domain of eip"
  default     = ""
}

// Service Endpoints
variable "create_s3_endpoint" {
  type        = bool
  description = "Create s3 endpoint"
  default     = true
}
variable "create_secrets_manager_endpoint" {
  type        = bool
  description = "Create secrets-manager endpoint"
  default     = true
}
variable "create_cloudwatch_logs_endpoint" {
  type        = bool
  description = "Create cloudwatch logs endpoint"
  default     = false
}

// Blocks
// Remember, AWS randomizes the availability zones per account, thus favoring the A-Z ordering has no consequences
// however you may want to change the order if a specific EC2 type has higher availability in a specific AZ
variable "subnet_azs" {
  type        = list(string)
  description = "List of public subnet availability zones"
  default     = [
    "a",
    "b",
    "c",
    "d",
    "e",
    "f"
  ]
}
variable "vpc_cidr" {
  description = "VPC cidr block"
  default     = "10.2.0.0/16"
}
variable "public_subnet_count" {
  type        = number
  description = "Number of public subnets"
  default     = 3
}
variable "public_subnet_cidr_blocks" {
  type        = list(string)
  description = "List of public subnet CIDR blocks"
  default     = [
    "10.2.0.0/20",
    "10.2.16.0/20",
    "10.2.32.0/20",
    "10.2.48.0/20",
    "10.2.64.0/20",
    "10.2.80.0/20"
  ]
}
variable "private_subnet_count" {
  type        = number
  description = "Number of private subnets"
  default     = 3
}
variable "private_subnet_cidr_blocks" {
  type        = list(string)
  description = "List of public subnet CIDR blocks"
  default     = [
    "10.2.160.0/20",
    "10.2.176.0/20",
    "10.2.192.0/20",
    "10.2.208.0/20",
    "10.2.224.0/20",
    "10.2.240.0/20"
  ]
}
variable "nat_gateway_arch" {
  type        = string
  description = "Architecture of the NAT Gateway"
  default     = "arm64"
}
variable "nat_key_name" {
  type        = string
  description = "Name of the key pair to use for the NAT Gateway"
}
variable "sg_ssh_ec2_connect_ips" {
  type        = list(string)
  description = "List of IPs to allow SSH access via EC2 Connect"
  default     = [""]
}
variable "sg_ssh_admin_name" {
  type        = string
  description = "Your name"
  default     = "admin"
}
variable "sg_ssh_admin_ipv4" {
  type        = string
  description = "IP to allow SSH access"
  default     = "172.16.1.0"
}
