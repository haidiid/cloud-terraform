# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

# --- Password: read ZooKeeper user password from local credential file ---
data "local_file" "zookeeper_user_password" {
  filename = "${path.module}/credential/user/zookeeper-password.pass"
}

# --- SSH Public Key: read SSH public key from local credential file ---
data "local_file" "ssh-public-key" {
  filename = "${path.root}/credential/ssh-public-key.pub"
}

data "local_file" "zookeeper_configuration_sudoers" {
  filename = "${path.module}/configuration/sudoers.d/zookeeper"
}

data "local_file" "zookeeper_configuration_rsyslog" {
  filename = "${path.module}/configuration/rsyslog/zookeeper.conf"
}

data "local_file" "zookeeper_configuration_systemd" {
  filename = "${path.module}/configuration/systemd/zookeeperd.service"
}

data "local_file" "zookeeper_configuration_properties" {
  filename = "${path.module}/configuration/properties/zookeeper.properties"
}

data "local_file" "zookeeper_configuration_log" {
  filename = "${path.module}/configuration/properties/logback.xml"
}

data "local_file" "zookeeper_configuration_myid" {
  filename = "${path.module}/configuration/properties/myid"
}

# --- TLS: PKCS12 keystore/truststore are binary, so they are passed as base64 (content_base64) ---
data "local_file" "zookeeper_tls_keystore" {
  filename = "${path.module}/credential/tls/zookeeper-server.p12"
}

data "local_file" "zookeeper_tls_truststore" {
  filename = "${path.module}/credential/tls/truststore.p12"
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

# define public a vm instance for zookeeper-server ---
resource "aws_instance" "main" {
  ami                         = var.instance_ami_id != null ? var.instance_ami_id : data.aws_ami.almalinux10[0].id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = true
  key_name                    = var.key_name
  user_data = templatefile("${path.module}/zookeeper-server.tfl", {
    zookeeper_username                 = var.zookeeper_username
    zookeeper_uri                      = var.zookeeper_uri
    zookeeper_password                 = trimspace(data.local_file.zookeeper_user_password.content)
    ssh-public-key                     = trimspace(data.local_file.ssh-public-key.content)
    zookeeper_configuration_sudoers    = trimspace(data.local_file.zookeeper_configuration_sudoers.content)
    zookeeper_configuration_properties = trimspace(data.local_file.zookeeper_configuration_properties.content)
    zookeeper_configuration_log        = trimspace(data.local_file.zookeeper_configuration_log.content)
    zookeeper_configuration_myid       = trimspace(data.local_file.zookeeper_configuration_myid.content)
    zookeeper_configuration_rsyslog    = trimspace(data.local_file.zookeeper_configuration_rsyslog.content)
    zookeeper_configuration_systemd    = trimspace(data.local_file.zookeeper_configuration_systemd.content)
    zookeeper_tls_keystore_base64      = data.local_file.zookeeper_tls_keystore.content_base64
    zookeeper_tls_truststore_base64    = data.local_file.zookeeper_tls_truststore.content_base64
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

# look up the pre-allocated Elastic IP (managed outside Terraform) ---
data "aws_eip" "zookeeper" {
  public_ip = var.zookeeper_eip_public_ip
}

# attach the Elastic IP to zookeeper-server so its public address is stable ---
resource "aws_eip_association" "zookeeper" {
  allocation_id = data.aws_eip.zookeeper.id
  instance_id   = aws_instance.main.id
}
