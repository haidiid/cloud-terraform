# Infrastructure Terraform Configuration

This repository provides Terraform configurations for deploying AWS infrastructure including VPC networking, subnets, route tables, security groups, and an EC2 instance running AlmaLinux 10 on amd64 architecture.

## Specifications

- **Operating System:** AlmaLinux 10 (x86_64 / amd64)
- **Instance Type:** `t3.small` (2 vCPUs, 2 GiB RAM, amd64)
- **Storage:** 15 GB gp3 encrypted root EBS volume
- **Networking:** Public subnet with automated public IP allocation (`associate_public_ip_address = true`)
- **Security:** Public security group attached with inbound/outbound rules

## Usage

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Review Execution Plan
```bash
terraform plan -var-file=local.tfvars
```

### 3. Apply Configuration
```bash
terraform apply -var-file=local.tfvars
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `aws_region` | AWS region to deploy resources | `string` | `"ap-southeast-2"` |
| `name` | Resource name prefix | `string` | `"main"` |
| `instance_type` | EC2 instance type (2 GiB RAM, amd64) | `string` | `"t3.small"` |
| `instance_root_volume_size` | Size of the root volume in GB | `number` | `15` |
| `instance_ami_id` | Optional AMI ID override | `string` | `null` |
| `key_name` | Optional SSH Key Pair name | `string` | `null` |
| `zookeeper_username` | Username for the ZooKeeper user | `string` | `"haidiid"` |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | ID of the created EC2 instance |
| `instance_public_ip` | Public IPv4 address assigned to the instance |
| `instance_public_dns` | Public DNS hostname of the instance |
| `instance_ami_id` | AMI ID used to launch the instance |
