# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---

# fetches all AWS Available Zones for select region
data "aws_availability_zones" "available" {
  state = "available"
}

# --- TLS: PKCS12 keystore/truststore are binary, so they are passed as base64 (content_base64) ---
data "local_file" "ssh_public_key" {
  filename = "${path.module}/credential/ssh-public-key.pub"
}

# defines used availability zones
locals {
  azs            = slice(data.aws_availability_zones.available.names, 0, var.total_availability_zone)
  ssh_public_key = data.local_file.ssh_public_key.content
}

# ---
# Defines a VPC, covering
#   - a vpc general spec
#   - three subnets
#   - two security groups
# ---
resource "aws_vpc" "local-vpc" {
  cidr_block           = var.vpc_reserved_network_id
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "local-${var.system_tag}"
  }
}

# Takes over the VPC's default security group and removes all its rules,
# so nothing is reachable by accident. The VM will get its own security group.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.local-vpc.id

  tags = {
    Name = "local-${var.system_tag}-default-deny"
  }
}

# defines a public subnet to allow application endpoints accessible through internet gateway (cidr)
#
resource "aws_security_group" "public-security-group" {
  name        = "local-${var.system_tag}-public-security-group-${var.aws_region}"
  description = "Security group for public subnet to receive incoming requests from internet gateway"
  vpc_id      = aws_vpc.local-vpc.id

  # defines receiving inbound traffic for SSH connection
  ingress {
    description = "Allow SSH inbound traffic from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # defines sending outbound traffic for SSH connection
  egress {
    description = "Allow SSH outbound traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # defines receiving incoming HTTP requests
  ingress {
    description = "Allow default http inbound traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow default http outbound traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # defines the Kerberos KDC ports (see ./kerberos-server)
  #    - ticket requests (AS/TGS) over UDP; over TCP they use port 80, already opened by the HTTP rule above
  #      (AWS rejects a duplicate tcp/80 rule)
  #    - kadmin over TCP
  #    - kpasswd over UDP and TCP
  ingress {
    description = "Allow Kerberos ticket requests over UDP"
    from_port   = 80
    to_port     = 80
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS outbound traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow HTTPS inbound traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # defines the Kerberos KDC ports (see ./kerberos-server)
  #    - ticket requests (AS/TGS) over UDP; over TCP they use port 80, already opened by the HTTP rule above
  #      (AWS rejects a duplicate tcp/80 rule)
  #    - kadmin over TCP
  #    - kpasswd over UDP and TCP
  ingress {
    description = "Allow Kerberos ticket requests over UDP"
    from_port   = 80
    to_port     = 80
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Kerberos kadmin over TCP"
    from_port   = 9811
    to_port     = 9811
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Kerberos kpasswd over TCP"
    from_port   = 9812
    to_port     = 9812
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Kerberos kpasswd over UDP"
    from_port   = 9812
    to_port     = 9812
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # lets Kerberos clients in this group (e.g. the ZooKeeper host) reach the KDC; tcp/80 egress is the HTTP rule above
  egress {
    description = "Allow Kerberos ticket requests outbound over UDP"
    from_port   = 80
    to_port     = 80
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow Kerberos kadmin outbound over TCP"
    from_port   = 9811
    to_port     = 9811
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow Kerberos kpasswd outbound over TCP"
    from_port   = 9812
    to_port     = 9812
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow Kerberos kpasswd outbound over UDP"
    from_port   = 9812
    to_port     = 9812
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "local-${var.system_tag}-public-security-group-${var.aws_region}"
  }
}

resource "aws_security_group" "private-security-group" {
  name        = "local-${var.system_tag}-private-security-group-${var.aws_region}"
  description = "Security group for private subnet allowing inbound traffic only from public subnet security group"
  vpc_id      = aws_vpc.local-vpc.id

  ingress {
    description     = "Allow inbound traffic from public subnet security group"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.public-security-group.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "local-${var.system_tag}-private-security-group-${var.aws_region}"
  }
}

# --- internet access ---
resource "aws_internet_gateway" "local-internet-gateway" {
  vpc_id = aws_vpc.local-vpc.id

  tags = {
    Name        = "local-${var.system_tag}-internet-gateway"
    Description = "Internet Gateway"
  }
}

# --- public subnets: instances get a public IP and route through the internet gateway ---
resource "aws_subnet" "local-public-subnet" {
  count = var.total_availability_zone

  vpc_id                  = aws_vpc.local-vpc.id
  cidr_block              = var.public_subnet_nework_id[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "local-${var.system_tag}-public-subnet-${local.azs[count.index]}"
    Tier = "public"
  }
}

# --- private subnets: no public IPs, outbound only through the optional NAT gateway ---
resource "aws_subnet" "private-subnet" {
  count = var.total_availability_zone

  vpc_id            = aws_vpc.local-vpc.id
  cidr_block        = var.private_subnet_nework_id[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "local-${var.system_tag}-private-subnet-${local.azs[count.index]}"
    Tier = "private"
  }
}

resource "aws_route_table" "public-subnet" {
  vpc_id = aws_vpc.local-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.local-internet-gateway.id
  }

  tags = {
    Name = "local-${var.system_tag}-public-subnet"
  }
}

resource "aws_route_table_association" "public-route-table" {
  count = var.total_availability_zone

  subnet_id      = aws_subnet.local-public-subnet[count.index].id
  route_table_id = aws_route_table.public-subnet.id
}

resource "aws_eip" "public-nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "local-${var.system_tag}-public-nat"
  }

  depends_on = [aws_internet_gateway.local-internet-gateway]
}

resource "aws_nat_gateway" "public-nat-gateway" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.public-nat[0].id
  subnet_id     = aws_subnet.local-public-subnet[0].id

  tags = {
    Name = "local-${var.system_tag}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.local-internet-gateway]
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.local-vpc.id

  dynamic "route" {
    for_each = aws_nat_gateway.public-nat-gateway
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = route.value.id
    }
  }

  tags = {
    Name = "local-${var.system_tag}-private-route-table"
  }
}

resource "aws_route_table_association" "private-route-table-association" {
  count = var.total_availability_zone

  subnet_id      = aws_subnet.private-subnet[count.index].id
  route_table_id = aws_route_table.private-route-table.id
}

