# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

# Kerberos server EC2 instance (see ./kerberos-server) ---
# same public subnet and security group as the ZooKeeper server
module "kerberos_server" {
  source = "./kerberos-server"

  environment_tag           = var.environment_tag
  kerberos_name_tag         = var.kerberos_name_tag
  kerberos_version_tag      = var.kerberos_version_tag
  name                      = var.name
  subnet_id                 = aws_subnet.public[0].id
  security_group_ids        = [aws_security_group.public.id]
  kerberos_instance_type    = var.kerberos_instance_type
  instance_root_volume_size = var.instance_root_volume_size
  instance_ami_id           = var.instance_ami_id
  key_name                  = var.key_name
  kerberos_username         = var.kerberos_username
  kerberos_eip_public_ip    = var.kerberos_eip_public_ip
}
