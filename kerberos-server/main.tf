# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

# --- Password: read the Kerberos user's password from local credential file ---
data "local_file" "kerberos_user_password" {
  filename = "${path.module}/configuration/user/password.pass"
}

# --- Kerberos: KDC database master password, client and admin principal passwords ---
data "local_file" "kerberos_realm_kdc_database_master_password" {
  filename = "${path.module}/credential/kerberos/realm-kdc-database-master-key-password.pass"
}

data "local_file" "kerberos_client_password" {
  filename = "${path.module}/credential/kerberos/${var.kerberos_client_principal}-principal.pass"
}

# "/" in the admin principal name (haidiid/admin) becomes "-" in its file name
data "local_file" "kerberos_admin_password" {
  filename = "${path.module}/credential/kerberos/${replace(var.kerberos_admin_principal, "/", "-")}-principal.pass"
}

# a service principal's file is named after its service part only (zookeeper/<host> -> zookeeper-principal.pass)
data "local_file" "kerberos_zookeeper_password" {
  filename = "${path.module}/credential/kerberos/${split("/", var.kerberos_zookeeper_principal)[0]}-principal.pass"
}

# --- Kerberos: krb5.conf, kdc.conf and kadm5.acl are plain files with hard-coded values ---
data "local_file" "kerberos_configuration_krb5" {
  filename = "${path.module}/configuration/krb5/krb5.conf"
}

data "local_file" "kerberos_configuration_kdc" {
  filename = "${path.module}/configuration/krb5/kdc.conf"
}

data "local_file" "kerberos_configuration_acl" {
  filename = "${path.module}/configuration/krb5/kadm5.acl"
}

data "local_file" "kerberos_configuration_sudoers" {
  filename = "${path.module}/configuration/sudoers.d/kerberos"
}

# uses alma linux specification to Kerberos KDC
data "aws_ami" "kerberos" {
  count       = var.kerberos_instance_ami_id == null ? 1 : 0
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

# look up the pre-allocated Elastic IP (managed outside Terraform) ---
data "aws_eip" "kerberos" {
  public_ip = var.public_ip
}

# ---
# Defines a Kerberos KDC instance with specification below
#    - selects alma linux 10 image (ami)
#    - selects t3.micro with 1 gig ram and 2 vcpus (instance_type)
#    - attaches to a VPC's public subnet (subnet_id)
#    - attaches to a public security group policy--connected to internet gateway (vpc_security_group_ids)
#    - enables to public ip exposure
#    - runs a terraform template-formatted bash provisioning shellscript (user_data)
#      that provisions the admin user and installs the Kerberos KDC and kadmind
# ---
resource "aws_instance" "kerberos" {
  ami                         = var.kerberos_instance_ami_id != null ? var.kerberos_instance_ami_id : data.aws_ami.kerberos[0].id
  instance_type               = var.kerberos_instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = true
  user_data = templatefile("${path.module}/kerberos-server.tfl", {
    kerberos_username              = var.kerberos_username
    kerberos_password              = trimspace(data.local_file.kerberos_user_password.content)
    ssh_public_key                 = trimspace(var.ssh_public_key)
    kerberos_configuration_sudoers = trimspace(data.local_file.kerberos_configuration_sudoers.content)
    kerberos_configuration_krb5    = trimspace(data.local_file.kerberos_configuration_krb5.content)
    kerberos_configuration_kdc     = trimspace(data.local_file.kerberos_configuration_kdc.content)
    kerberos_configuration_acl     = trimspace(data.local_file.kerberos_configuration_acl.content)
    kerberos_hostname              = var.kerberos_hostname
    kerberos_realm                 = var.kerberos_realm
    kerberos_kdc_port              = var.kerberos_kdc_port
    kerberos_kadmin_port           = var.kerberos_kadmin_port
    kerberos_kpasswd_port          = var.kerberos_kpasswd_port
    kerberos_master_password       = trimspace(data.local_file.kerberos_realm_kdc_database_master_password.content)
    kerberos_client_principal      = var.kerberos_client_principal
    kerberos_client_password       = trimspace(data.local_file.kerberos_client_password.content)
    kerberos_admin_principal       = var.kerberos_admin_principal
    kerberos_admin_password        = trimspace(data.local_file.kerberos_admin_password.content)
    kerberos_zookeeper_principal   = var.kerberos_zookeeper_principal
    kerberos_zookeeper_password    = trimspace(data.local_file.kerberos_zookeeper_password.content)
  })

  root_block_device {
    volume_size           = var.kerberos_instance_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.environment_tag}-${var.system_tag}-${var.kerberos_name_tag}-root-volume"
    }
  }

  tags = {
    Name    = "${var.environment_tag}-${var.system_tag}-${var.kerberos_name_tag}"
    Version = var.kerberos_version_tag
  }
}

resource "aws_eip_association" "kerberos" {
  allocation_id = data.aws_eip.kerberos.id
  instance_id   = aws_instance.kerberos.id
}

# ---
# Waits until the KDC's first boot (user_data, run by cloud-init) has finished, then moves the ZooKeeper keytab
# from the KDC to the local machine. Terraform marks the instance created as soon as AWS reports it running, so
# without this step anything depending on this module would start while the KDC is still provisioning.
#    - runs once per KDC instance (triggers_replace), from the machine running terraform (local-exec, PowerShell)
#      inside this module's folder (working_dir), so the keytab path is relative to kerberos-server/
#    - reaches the KDC by its hostname, which public DNS resolves to the Elastic IP
#    - forgets the old host keys of the hostname and Elastic IP, since every new instance has a new one
#    - polls "cloud-init status" over ssh every 15 seconds, for up to 15 minutes
#    - copies /home/<kerberos user>/zookeeper.keytab to ../zookeeper-server/credential/kerberos/, then deletes
#      it on the KDC
# ---
resource "terraform_data" "kerberos_ready" {
  triggers_replace = [aws_instance.kerberos.id]

  depends_on = [aws_eip_association.kerberos]

  provisioner "local-exec" {
    working_dir = path.module
    interpreter = ["PowerShell", "-NoProfile", "-Command"]
    command     = <<-EOT
      $target = "${var.kerberos_username}@${var.kerberos_hostname}"
      $keytab = "/home/${var.kerberos_username}/zookeeper.keytab"
      $local  = "../zookeeper-server/credential/kerberos/zookeeper.keytab"
      ssh-keygen -R "${var.kerberos_hostname}" *> $null
      ssh-keygen -R "${var.public_ip}" *> $null

      $status = ""
      for ($i = 0; $i -lt 60; $i++) {
        $status = (ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 $target "sudo -n cloud-init status" 2> $null) -join " "
        if ($status -match "status: (done|error)") { break }
        Write-Output "waiting for the KDC first boot to finish ($($i + 1)/60)"
        Start-Sleep -Seconds 15
      }
      if ($status -notmatch "status: done") { Write-Error "KDC first boot did not finish: $status"; exit 1 }

      scp -o BatchMode=yes "$${target}:$keytab" $local
      if ($LASTEXITCODE -ne 0) { Write-Error "could not copy $keytab from the KDC"; exit 1 }
      ssh -o BatchMode=yes $target "rm -f $keytab"
      Write-Output "KDC is ready; ZooKeeper keytab saved to $local"
    EOT
  }
}
