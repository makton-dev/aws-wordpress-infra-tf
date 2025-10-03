#############################################################################
# This file maintains Data objects used for the project
#############################################################################

data "aws_caller_identity" "current" {}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

# Using latest Amazon Linux 2023
data "aws_ami" "latest" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }

  filter {
    name   = "architecture"
    values = [var.ami_architecture]
  }
}
