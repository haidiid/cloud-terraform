# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

output "instance_id" {
  value = aws_instance.kerberos.id
}

output "public_ip" {
  description = "Elastic IP address associated with the instance."
  value       = aws_eip_association.kerberos.public_ip
}

output "public_dns" {
  value = aws_instance.kerberos.public_dns
}

output "ami_id" {
  value = aws_instance.kerberos.ami
}

output "ready_id" {
  description = "Known only once the KDC's first boot has finished and the ZooKeeper keytab was copied; depend on it to run after the KDC."
  value       = terraform_data.kerberos_ready.id
}
