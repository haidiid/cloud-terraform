# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

variable "name" {
  description = "Name prefix used in the Name tag of every resource."
  type        = string
}

variable "subnet_id" {
  description = "ID of the (public) subnet to launch the ZooKeeper instance in."
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs attached to the ZooKeeper instance."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "instance_root_volume_size" {
  description = "Size of the root EBS volume in GB."
  type        = number
}

variable "instance_ami_id" {
  description = "Optional AMI ID override. If null, the latest official AlmaLinux 10 x86_64 AMI is looked up."
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
}

variable "zookeeper_uri" {
  description = "ZooKeeper application binary tarball URL."
  type        = string
}

variable "zookeeper_eip_public_ip" {
  description = "Public IPv4 of the pre-allocated Elastic IP to associate with the instance."
  type        = string
}
