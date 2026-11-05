# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---
variable "aws_region" {
  description = "AWS region for every resource. Overridden by aws_region in terraform.tfvars."
  type        = string
  default     = "ap-southeast-2"
}

variable "name" {
  description = "Name prefix used in the Name tag of every resource."
  type        = string
  default     = "main"
}

variable "main_vpc_reserved_network_id_and_cidr" {
  description = "CIDR block of the VPC. Subnets are carved out of it as /25s."
  type        = string
  default     = "10.0.0.0/24"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.0.0/25"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.0.128/25"]
}

variable "az_count" {
  description = "Number of availability zones to spread the subnets over (one public and one private subnet per AZ)."
  type        = number
  default     = 1

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "az_count must be between 1 and 3."
  }
}

variable "enable_nat_gateway" {
  description = "Create a single NAT gateway so private subnets can reach the internet. It is billed per hour, so it is off by default."
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "EC2 instance type (t3.small provides 2 GiB RAM on x86_64/amd64 architecture)."
  type        = string
  default     = "t3.small"
}

variable "instance_root_volume_size" {
  description = "Size of the root EBS volume in GB."
  type        = number
  default     = 15
}

variable "instance_ami_id" {
  description = "Optional AMI ID override for the instance. If omitted, the latest official AlmaLinux 10 x86_64 AMI is automatically looked up."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Optional key pair name to assign to the instance for SSH access."
  type        = string
  default     = null
}

variable "zookeeper_username" {
  description = "Username for the ZooKeeper user created on the instance."
  type        = string
  default     = "haidiid"
}

variable "zookeeper_uri" {
  description = "Zookeeper Application binary tarball on the instance"
  type        = string
  default     = "https://dlcdn.apache.org/zookeeper/zookeeper-3.8.8/apache-zookeeper-3.8.8-bin.tar.gz"
}
