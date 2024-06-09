module "vpc" {
  source = "./networking/vpc"

  enable_nat_gateway = true

  name            = "devops-vpc"
  cidr            = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  single_nat_gateway = true
  # Error will occur in cases where we are trying to create public subnets < number of azs

  tags = {
    "Created-By" = "Terraform"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}