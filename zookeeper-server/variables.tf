# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
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

variable "subnet_id" {
  description = "ID of the (public) subnet to launch the ZooKeeper instance in."
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs attached to the ZooKeeper instance."
  type        = list(string)
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
  description = "Service component of the ZooKeeper instance Name tag. Set in *.tfvars."
  type        = string
}

variable "zookeeper_version_tag" {
  description = "Value of the Version tag on the ZooKeeper instance. Set in *.tfvars."
  type        = string
}

variable "zookeeper_instance_type" {
  description = "EC2 instance type (t3.small provides 2 GiB RAM on x86_64/amd64 architecture)."
  type        = string
}

variable "zookeeper_instance_ami_id" {
  description = "Optional AMI ID for the ZooKeeper instance. When null, the latest matching AlmaLinux 10 AMI is selected."
  type        = string
  default     = null
}

variable "zookeeper_instance_volume_size" {
  description = "EC2 instance type (t3.small provides 2 GiB RAM on x86_64/amd64 architecture)."
  type        = string
}

variable "ssh_public_key" {
  description = "Optional key pair name to assign to the instance for SSH access."
  type        = string
}

variable "zookeeper_username" {
  description = "Username for the ZooKeeper user created on the instance."
  type        = string
}

variable "zookeeper_uri" {
  description = "Zookeeper Application binary tarball on the instance"
  type        = string
}

variable "kerberos_ready_id" {
  description = "Kerberos module's ready_id; the ZooKeeper instance is created only after the KDC is ready."
  type        = string
}
