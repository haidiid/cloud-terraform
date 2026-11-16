# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

output "instance_id" {
  value = aws_instance.main.id
}

output "public_ip" {
  description = "Elastic IP address associated with the instance."
  value       = aws_eip_association.kerberos.public_ip
}

output "private_ip" {
  value = aws_instance.main.private_ip
}

output "public_dns" {
  value = aws_instance.main.public_dns
}

output "ami_id" {
  value = aws_instance.main.ami
}
