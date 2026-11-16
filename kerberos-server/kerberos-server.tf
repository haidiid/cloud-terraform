# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

# ---
# this terraform script is designated for building Kerberos KDC Server
# ---

# imports an instance's user password
data "local_file" "kerberos_user_password" {
  filename = "${path.module}/credential/user/kerberos-password.pass"
}

# imports an instance's user ssh acces
data "local_file" "ssh-public-key" {
  filename = "${path.root}/credential/ssh-public-key.pub"
}

# imports an instance's user elevated root access
data "local_file" "kerberos_configuration_sudoers" {
  filename = "${path.module}/configuration/sudoers.d/kerberos"
}

# defines alma linux 10 for the instance's image
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

# imports pre-allocated eip designated for this instance
data "aws_eip" "kerberos" {
  public_ip = var.kerberos_eip_public_ip
}

# defines the instance's name tag
#    - it follows this format <environment>-<instance>-<vm node number>
#      e.g: local-kerberos-vm0
locals {
  vm_name_tag = "${var.environment_tag}-${var.kerberos_name_tag}-vm0"
}

# defines ec2 instance-
resource "aws_instance" "main" {
  ami                         = var.instance_ami_id != null ? var.instance_ami_id : data.aws_ami.almalinux10[0].id
  instance_type               = var.kerberos_instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = true
  key_name                    = var.key_name
  user_data = templatefile("${path.module}/kerberos-server.tfl", {
    kerberos_username              = var.kerberos_username
    kerberos_password              = trimspace(data.local_file.kerberos_user_password.content)
    ssh-public-key                 = trimspace(data.local_file.ssh-public-key.content)
    kerberos_configuration_sudoers = trimspace(data.local_file.kerberos_configuration_sudoers.content)
  })

  root_block_device {
    volume_size           = var.instance_root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name    = "${local.vm_name_tag}-root-volume"
      Version = var.kerberos_version_tag
    }
  }

  tags = {
    Name    = local.vm_name_tag
    Version = var.kerberos_version_tag
  }

  # a newer AlmaLinux AMI must not replace the running instance on a later apply
  lifecycle {
    ignore_changes = [ami]
  }
}

# attaches the eip to this instance's ec2---
resource "aws_eip_association" "kerberos" {
  allocation_id = data.aws_eip.kerberos.id
  instance_id   = aws_instance.main.id
}
