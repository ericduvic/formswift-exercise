locals {
  app             = "helloworld"

  cidr            = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"

  name               = "${local.app}-vpc"
  cidr               = local.cidr

  azs                = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets    = local.private_subnets
  public_subnets     = local.public_subnets

  enable_nat_gateway = true

  tags = {
    Terraform   = "true"
  }
}

module "fargate" {
  source      = "../modules/simple-fargate"

  app         = local.app

  vpc_id      = module.vpc.vpc_id
  app_subnets = module.vpc.private_subnets
  lb_subnets  = module.vpc.public_subnets
}