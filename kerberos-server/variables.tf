# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

variable "environment_tag" {
  description = "Environment component of the Name tag."
  type        = string
}

variable "system_tag" {
  description = "System component of the Name tag."
  type        = string
}

variable "public_ip" {
  description = "Public IPv4 of the pre-allocated Elastic IP to associate with the Kerberos instance."
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

variable "ssh_public_key" {
  description = "SSH public key installed in the Kerberos user's authorized_keys."
  type        = string
}

# ---
# Defines Kerberos instance variables, covering
#    - instance's name tag
#    - instance's version tag
#    - image and instance type
#    - root volume size
#    - provision script instance's user
# ---
variable "kerberos_name_tag" {
  description = "Service component of the Kerberos instance Name tag."
  type        = string
}

variable "kerberos_version_tag" {
  description = "Value of the Version tag on the Kerberos instance."
  type        = string
}

variable "kerberos_instance_type" {
  description = "EC2 instance type (t3.micro provides 1 GiB RAM on x86_64/amd64 architecture)."
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

# ---
# Defines Kerberos KDC variables, covering
#    - realm and KDC hostname
#    - ticket request (kdc), kadmin and kpasswd ports
#    - client and admin principal names (without realm)
# ---
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
  description = "Client principal name without realm; its password is read from credential/kerberos/<name>-principal.pass."
  type        = string
}

variable "kerberos_admin_principal" {
  description = "Admin principal name without realm (e.g. haidiid/admin); its password is read from credential/kerberos/<name with / as ->-principal.pass."
  type        = string
}

variable "kerberos_zookeeper_principal" {
  description = "ZooKeeper service principal name without realm (e.g. zookeeper/zookeeper.haidi.online); its password is read from credential/kerberos/<service name before />-principal.pass."
  type        = string
}
