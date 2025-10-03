#############################################################################
# Backend configuration and Provider config
#############################################################################

# If you are using this for AWS resources, might as well use an S3 Bucket
# for the state file. 
terraform {

  backend "s3" {
    bucket = "" # REQUIRED: change to your AWS bucket for Terraform State Files
    key    = "" # REQUIRED: the name of the state file
  }

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.14"
    }
  }

}

# can set your region profile, and default tags.
provider "aws" {
  profile = ""
  region  = ""

  # these will be added to all resources and good for managing the project resources
  default_tags {
    tags = {
      "Application" = "WordPress Infrastructure"
    }
  }
}
