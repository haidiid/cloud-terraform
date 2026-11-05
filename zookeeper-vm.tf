# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

# --- Password: read ZooKeeper user password from local credential file ---
data "local_file" "zookeeper_user_password" {
  filename = "${path.module}/credential/user-password.txt"
}

# --- SSH Public Key: read SSH public key from local credential file ---
data "local_file" "ssh-public-key" {
  filename = "${path.module}/credential/ssh-public-key.pub"
}

data "local_file" "zookeeper_configuration_sudoers" {
  filename = "${path.module}/configuration/zookeeper-vm/sudoers.d/zookeeper"
}

data "local_file" "zookeeper_configuration_rsyslog" {
  filename = "${path.module}/configuration/zookeeper-vm/rsyslog/zookeeper.conf"
}

data "local_file" "zookeeper_configuration_systemd" {
  filename = "${path.module}/configuration/zookeeper-vm/systemd/zookeeperd.service"
}

data "local_file" "zookeeper_configuration_properties" {
  filename = "${path.module}/configuration/zookeeper-vm/properties/zookeeper.properties"
}

data "local_file" "zookeeper_configuration_log" {
  filename = "${path.module}/configuration/zookeeper-vm/properties/logback.xml"
}

data "local_file" "zookeeper_configuration_myid" {
  filename = "${path.module}/configuration/zookeeper-vm/properties/myid"
}

# --- AMI: Official AlmaLinux 10 (x86_64 / amd64) ---
data "aws_ami" "almalinux10" {
  count       = var.instance_ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["764336703387"] # AlmaLinux OS Foundation

  filter {
    name   = "name"
    values = ["AlmaLinux OS 10*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# define public a vm instance for zookeeper-vm ---
resource "aws_instance" "main" {
  ami                         = var.instance_ami_id != null ? var.instance_ami_id : data.aws_ami.almalinux10[0].id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.public.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  user_data = templatefile("zookeeper.tfl", {
    zookeeper_username                 = var.zookeeper_username
    zookeeper_uri                      = var.zookeeper_uri
    zookeeper_password                 = trimspace(data.local_file.zookeeper_user_password.content)
    ssh-public-key                     = trimspace(data.local_file.ssh-public-key.content)
    zookeeper_configuration_sudoers    = trimspace(data.local_file.zookeeper_configuration_sudoers.content)
    zookeeper_configuration_properties = trimspace(data.local_file.zookeeper_configuration_properties.content)
    zookeeper_configuration_log = trimspace(data.local_file.zookeeper_configuration_log.content)
    zookeeper_configuration_myid = trimspace(data.local_file.zookeeper_configuration_myid.content)
    zookeeper_configuration_rsyslog = trimspace(data.local_file.zookeeper_configuration_rsyslog.content)
    zookeeper_configuration_systemd = trimspace(data.local_file.zookeeper_configuration_systemd.content)
  })

  root_block_device {
    volume_size           = var.instance_root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.name}-root-volume"
    }
  }

  tags = {
    Name = "${var.name}-almalinux10"
  }
}
