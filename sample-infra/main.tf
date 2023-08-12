terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.47.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
  default_tags {
    tags = {
      owner = "automation-samples"
    }
  }
}

resource "aws_key_pair" "ec2loginkey" {
  key_name = "login-key"
  public_key = file(pathexpand(var.ssh_pair_public_key))
}
