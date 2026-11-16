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

variable "zookeeper_eip_public_ip" {
  description = "Public IPv4 of the pre-allocated Elastic IP (created outside Terraform) to associate with the ZooKeeper instance."
  type        = string
  default     = "15.134.165.145"
}

variable "kafka_username" {
  description = "Username for the Kafka OS user created on the Kafka broker instance."
  type        = string
  default     = "haidiid"
}

variable "kafka_uri" {
  description = "Kafka application binary tarball. Must be a 3.x release: Kafka 4 no longer supports ZooKeeper."
  type        = string
  default     = "https://archive.apache.org/dist/kafka/3.9.2/kafka_2.13-3.9.2.tgz"
}

variable "kafka_advertised_host" {
  description = "Host name clients use to reach the Kafka broker. Must resolve to the broker's public IP and be listed in the broker certificate's subjectAltName."
  type        = string
  default     = "kafka-0.haidi.online"
}

variable "kerberos_username" {
  description = "Username for the OS user created on the Kerberos instance."
  type        = string
  default     = "haidiid"
}

variable "kerberos_eip_public_ip" {
  description = "Public IPv4 of the pre-allocated Elastic IP (created outside Terraform) to associate with the Kerberos instance."
  type        = string
  default     = "16.178.63.195"
}

variable "environment_tag" {
  description = "environment name component in a ec2 instance name tag which the corresponding values comprising of local, pre-prod, and prod. Set in *.tfvars."
  type        = string
}

variable "kerberos_name_tag" {
  description = "Service component of the Kerberos instance Name tag (e.g. kerberos). Set in *.tfvars."
  type        = string
}

variable "kerberos_version_tag" {
  description = "Value of the Version tag on the Kerberos instance (e.g. 0.0.1). Set in *.tfvars."
  type        = string
}

variable "kerberos_instance_type" {
  description = "EC2 instance type of the Kerberos instance (e.g. t3.micro, 1 GiB RAM). Set in *.tfvars."
  type        = string
}
