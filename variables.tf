# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

# ---
# Defines global variables, covering
#    - global tagging, including environment_tag & system_tag
#    - public ip for local deployment
#         - a vpc specs including
#         - region (aws_region) and its corresponding availability zones
#         - CIDR ranges for vpc covering two subnets /25, in total consists of vpc, public subnet, and private subnet cidrs
# ---
variable "environment_tag" {
  description = "Public IPv4 of the pre-allocated Elastic IP to associate with the instance."
  type        = string
}

variable "system_tag" {
  description = "Public IPv4 of the pre-allocated Elastic IP to associate with the instance."
  type        = string
}

variable "public_ip" {
  description = "Public IPv4 of the pre-allocated Elastic IP to associate with the instance."
  type        = string
}

variable "second_public_ip" {
  description = "Public IPv4 of the pre-allocated Elastic IP to associate with the Kerberos KDC instance."
  type        = string
}

variable "aws_region" {
  description = "AWS region for every resource. Overridden by aws_region in terraform.tfvars."
  type        = string
  default     = "ap-southeast-2"
}

variable "total_availability_zone" {
  description = "Number of availability zones to spread the subnets over (one public and one private subnet per AZ)."
  type        = number
  default     = 1

  validation {
    condition     = var.total_availability_zone >= 1 && var.total_availability_zone <= 3
    error_message = "total_availability_zone (Total of Availability Zones) must be between 1 and 3."
  }
}

variable "vpc_reserved_network_id" {
  description = "CIDR block of the VPC. Subnets are carved out of it as /25s."
  type        = string
  default     = "10.0.0.0/24"
}

variable "public_subnet_nework_id" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.0.0/25"]
}

variable "private_subnet_nework_id" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.0.128/25"]
}

# i forgot this, i'll ask Claude later
variable "enable_nat_gateway" {
  description = "Create a single NAT gateway so private subnets can reach the internet. It is billed per hour, so it is off by default."
  type        = bool
  default     = false
}

# ---
# Defines ZooKeeper instance variables, covering
#    - instance's name tag
#    - instance's version tag
#    - image type
#    - provision script instance's user
#    - provision script Zookeeper Installer Source URI
# ---
variable "zookeeper_name_tag" {
  description = "Service component of the ZooKeeper instance Name tag."
  type        = string
  default     = "zookeeper"
}

variable "zookeeper_version_tag" {
  description = "ZooKeeper version recorded on the instance Version tag."
  type        = string
  default     = "3.8.8"
}

variable "zookeeper_instance_type" {
  description = "EC2 instance type of the ZooKeeper instance."
  type        = string
  default     = "t3.small"
}

variable "zookeeper_instance_ami_id" {
  description = "Optional AMI ID for the ZooKeeper instance. When null, the latest matching AlmaLinux 10 AMI is selected."
  type        = string
  default     = null
}

variable "zookeeper_instance_volume_size" {
  description = "Root volume size in GiB for the ZooKeeper instance."
  type        = string
  default     = "15"
}

variable "zookeeper_username" {
  description = "Username for the ZooKeeper user created on the instance."
  type        = string
  default     = "haidiid"
}

variable "zookeeper_uri" {
  description = "ZooKeeper application binary tarball URI."
  type        = string
  default     = "https://dlcdn.apache.org/zookeeper/zookeeper-3.8.8/apache-zookeeper-3.8.8-bin.tar.gz"
}

# ---
# Defines Kerberos KDC instance variables, covering
#    - instance's name tag
#    - instance's version tag
#    - image type (t3.micro: 1 GiB RAM) and root volume size (15 GiB)
#    - provision script instance's user
# ---
variable "kerberos_name_tag" {
  description = "Service component of the Kerberos instance Name tag."
  type        = string
}

variable "kerberos_version_tag" {
  description = "Kerberos (MIT krb5) version recorded on the instance Version tag."
  type        = string
}

variable "kerberos_instance_type" {
  description = "EC2 instance type of the Kerberos instance (t3.micro provides 1 GiB RAM)."
  type        = string
}

variable "kerberos_instance_ami_id" {
  description = "Optional AMI ID for the Kerberos instance. When null, the latest matching AlmaLinux 10 AMI is selected."
  type        = string
}

variable "kerberos_instance_volume_size" {
  description = "Root volume size in GiB for the Kerberos instance."
  type        = number
}

variable "kerberos_username" {
  description = "Username for the admin user created on the Kerberos instance."
  type        = string
}

variable "kerberos_realm" {
  description = "Kerberos realm served by the KDC."
  type        = string
}

variable "kerberos_hostname" {
  description = "Fully qualified hostname of the KDC."
  type        = string
}

variable "kerberos_kdc_port" {
  description = "UDP and TCP port the KDC accepts ticket requests on."
  type        = number
}

variable "kerberos_kadmin_port" {
  description = "TCP port of the kadmin service."
  type        = number
}

variable "kerberos_kpasswd_port" {
  description = "UDP and TCP port of the kpasswd service."
  type        = number
}

variable "kerberos_client_principal" {
  description = "Client principal name without realm."
  type        = string
}

variable "kerberos_admin_principal" {
  description = "Admin principal name without realm; matches */admin in kadm5.acl."
  type        = string
}

variable "kerberos_zookeeper_principal" {
  description = "ZooKeeper service principal name without realm (service/host)."
  type        = string
}
