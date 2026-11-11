# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---
output "vpc_id" {
  value = aws_vpc.main.id
}

output "main_vpc_reserved_network_id_and_cidr" {
  value = aws_vpc.main.cidr_block
}

output "availability_zones" {
  value = local.azs
}

output "public_subnet_ids" {
  description = "Put the VM here to reach it on port 22 (SSH) and port 80 (HTTP)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}

output "public_security_group_id" {
  description = "ID of the security group for the public subnet."
  value       = aws_security_group.public.id
}

output "private_security_group_id" {
  description = "ID of the security group for the private subnet."
  value       = aws_security_group.private.id
}

output "nat_gateway_id" {
  value = one(aws_nat_gateway.main[*].id)
}

output "instance_id" {
  description = "ID of the created AlmaLinux 10 EC2 instance."
  value       = module.zookeeper_server.instance_id
}

output "instance_public_ip" {
  description = "Elastic IP address associated with the AlmaLinux 10 EC2 instance."
  value       = module.zookeeper_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name assigned to the AlmaLinux 10 EC2 instance."
  value       = module.zookeeper_server.public_dns
}

output "instance_ami_id" {
  description = "AMI ID used for launching the AlmaLinux 10 EC2 instance."
  value       = module.zookeeper_server.ami_id
}
