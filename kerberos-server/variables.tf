# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

# Name tag = <environment_tag>-<kerberos_name_tag>-vm0
variable "environment_tag" {
  description = "name tag's environment component"
  type        = string
}

variable "kerberos_name_tag" {
  description = "name tag's service component"
  type        = string
}

variable "kerberos_version_tag" {
  description = "Value of the Version tag on the Kerberos instance."
  type        = string
}

variable "name" {
  description = "Name prefix used in the Name tag of every resource."
  type        = string
}

variable "subnet_id" {
  description = "ID of the (public) subnet to launch the Kerberos instance in."
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs attached to the Kerberos instance."
  type        = list(string)
}

variable "kerberos_instance_type" {
  description = "EC2 instance type of the Kerberos instance (t3.micro provides 1 GiB RAM, enough for a KDC)."
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

variable "kerberos_username" {
  description = "Username for the OS user created on the Kerberos instance."
  type        = string
}

variable "kerberos_eip_public_ip" {
  description = "Public IPv4 of the pre-allocated Elastic IP to associate with the instance."
  type        = string
}
