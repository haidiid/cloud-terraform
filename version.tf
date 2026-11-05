# ---
# Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
# Cirebon, GPLv3 License
# ---


# defines required version for Terraform and AWS provider
terraform {
  # define minimum terraform version
  required_version = ">= 1.16.6"

  # define minimum provider version
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # # defina terraform's state storage
  # backend "s3" {}
}