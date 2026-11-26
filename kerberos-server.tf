# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

# ---
# the KDC ports (ticket, kadmin, kpasswd) are opened in the public security group (see main.tf).
# ---

# Kerberos KDC server EC2 instance (see ./kerberos-server for the detail) ---
module "kerberos_server" {
  source = "./kerberos-server"

  environment_tag    = var.environment_tag
  system_tag         = var.system_tag
  subnet_id          = aws_subnet.local-public-subnet[0].id
  security_group_ids = [aws_security_group.public-security-group.id]
  ssh_public_key     = local.ssh_public_key
  public_ip          = var.second_public_ip

  kerberos_name_tag             = var.kerberos_name_tag
  kerberos_version_tag          = var.kerberos_version_tag
  kerberos_instance_type        = var.kerberos_instance_type
  kerberos_instance_ami_id      = var.kerberos_instance_ami_id
  kerberos_instance_volume_size = var.kerberos_instance_volume_size
  kerberos_username             = var.kerberos_username

  kerberos_realm            = var.kerberos_realm
  kerberos_hostname         = var.kerberos_hostname
  kerberos_kdc_port         = var.kerberos_kdc_port
  kerberos_kadmin_port      = var.kerberos_kadmin_port
  kerberos_kpasswd_port     = var.kerberos_kpasswd_port
  kerberos_client_principal = var.kerberos_client_principal
  kerberos_admin_principal  = var.kerberos_admin_principal

  kerberos_zookeeper_principal = var.kerberos_zookeeper_principal
}
