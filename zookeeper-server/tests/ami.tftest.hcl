mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id = "ami-fallback"
    }
  }

  mock_data "aws_eip" {
    defaults = {
      id = "eipalloc-00000000"
    }
  }
}

mock_provider "local" {
  mock_data "local_file" {
    defaults = {
      content        = "test"
      content_base64 = "dGVzdA=="
    }
  }
}

run "uses_discovered_ami_when_override_omitted" {
  command = plan

  variables {
    environment_tag                = "test"
    system_tag                     = "test"
    public_ip                      = "203.0.113.1"
    subnet_id                      = "subnet-00000000"
    security_group_ids             = ["sg-00000000"]
    ssh_public_key                 = ""
    zookeeper_name_tag             = "zookeeper"
    zookeeper_version_tag          = "3.8.8"
    zookeeper_instance_type        = "t3.small"
    zookeeper_instance_volume_size = "15"
  }

  assert {
    condition     = aws_instance.zookeeper.ami == "ami-fallback"
    error_message = "The default AMI lookup should supply the ZooKeeper AMI."
  }

  assert {
    condition     = length(data.aws_ami.zookeeper) == 1
    error_message = "The default AMI lookup should run when no override is supplied."
  }
}

run "uses_discovered_ami_when_override_is_null" {
  command = plan

  variables {
    environment_tag                = "test"
    system_tag                     = "test"
    public_ip                      = "203.0.113.1"
    subnet_id                      = "subnet-00000000"
    security_group_ids             = ["sg-00000000"]
    ssh_public_key                 = ""
    zookeeper_name_tag             = "zookeeper"
    zookeeper_version_tag          = "3.8.8"
    zookeeper_instance_type        = "t3.small"
    zookeeper_instance_ami_id      = null
    zookeeper_instance_volume_size = "15"
  }

  assert {
    condition     = aws_instance.zookeeper.ami == "ami-fallback"
    error_message = "A null AMI override should use the discovered ZooKeeper AMI."
  }

  assert {
    condition     = length(data.aws_ami.zookeeper) == 1
    error_message = "The default AMI lookup should run when the override is null."
  }
}

run "uses_explicit_ami_without_lookup" {
  command = plan

  variables {
    environment_tag                = "test"
    system_tag                     = "test"
    public_ip                      = "203.0.113.1"
    subnet_id                      = "subnet-00000000"
    security_group_ids             = ["sg-00000000"]
    ssh_public_key                 = ""
    zookeeper_name_tag             = "zookeeper"
    zookeeper_version_tag          = "3.8.8"
    zookeeper_instance_type        = "t3.small"
    zookeeper_instance_ami_id      = "ami-explicit"
    zookeeper_instance_volume_size = "15"
  }

  assert {
    condition     = aws_instance.zookeeper.ami == "ami-explicit"
    error_message = "The ZooKeeper instance should use the explicit AMI override."
  }

  assert {
    condition     = length(data.aws_ami.zookeeper) == 0
    error_message = "The default AMI lookup should be skipped when an override is supplied."
  }
}