# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

# ZooKeeper server EC2 instance (see ./zookeeper-server for the detail) ---
module "zookeeper_server" {
  source = "./zookeeper-server"

  environment_tag    = var.environment_tag
  system_tag         = var.system_tag
  subnet_id          = aws_subnet.local-public-subnet[0].id
  security_group_ids = [aws_security_group.public-security-group.id]
  ssh_public_key     = local.ssh_public_key
  public_ip          = var.public_ip

  zookeeper_name_tag             = var.zookeeper_name_tag
  zookeeper_version_tag          = var.zookeeper_version_tag
  zookeeper_instance_type        = var.zookeeper_instance_type
  zookeeper_instance_ami_id      = var.zookeeper_instance_ami_id
  zookeeper_instance_volume_size = var.zookeeper_instance_volume_size
  zookeeper_username             = var.zookeeper_username
  zookeeper_uri                  = var.zookeeper_uri

  # the instance is created only after the Kerberos KDC has finished its first boot and handed over the
  # ZooKeeper keytab. not a module-wide depends_on: that would defer the module's data sources to apply time
  # whenever the KDC changes, and the unknown AMI would force the ZooKeeper instance to be replaced.
  kerberos_ready_id = module.kerberos_server.ready_id
}

# keep the existing instance in state instead of destroying and recreating it ---
moved {
  from = aws_instance.zookeeper
  to   = module.zookeeper_server.aws_instance.zookeeper
}
