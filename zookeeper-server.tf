# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

# ZooKeeper server EC2 instance (see ./zookeeper-server) ---
module "zookeeper_server" {
  source = "./zookeeper-server"

  name                      = var.name
  subnet_id                 = aws_subnet.public[0].id
  security_group_ids        = [aws_security_group.public.id]
  instance_type             = var.instance_type
  instance_root_volume_size = var.instance_root_volume_size
  instance_ami_id           = var.instance_ami_id
  key_name                  = var.key_name
  zookeeper_username        = var.zookeeper_username
  zookeeper_uri             = var.zookeeper_uri
  zookeeper_eip_public_ip   = var.zookeeper_eip_public_ip
}

# keep the existing instance in state instead of destroying and recreating it ---
moved {
  from = aws_instance.main
  to   = module.zookeeper_server.aws_instance.main
}
