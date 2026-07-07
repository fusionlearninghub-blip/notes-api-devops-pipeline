terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Remote state — S3 bucket + DynamoDB lock table must be created once,
  # manually, before first `terraform init` (see README "First-time setup").
  backend "s3" {
    bucket         = "kingsley-devops-tfstate" # change this if the bucket name was taken
    key            = "notes-api/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

module "network" {
  source  = "../../modules/network"
  project = var.project
  tags    = local.common_tags
}

module "alb" {
  source             = "../../modules/alb"
  project            = var.project
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  container_port     = var.container_port
  tags               = local.common_tags
}

module "ecs" {
  source                 = "../../modules/ecs"
  project                = var.project
  aws_region             = var.aws_region
  vpc_id                 = module.network.vpc_id
  private_subnet_ids     = module.network.private_subnet_ids
  alb_security_group_id  = module.alb.alb_security_group_id
  target_group_arn       = module.alb.target_group_arn
  container_port         = var.container_port
  image_tag               = var.image_tag
  desired_count           = var.desired_count
  tags                    = local.common_tags
}

module "monitoring" {
  source                   = "../../modules/monitoring"
  project                  = var.project
  aws_region               = var.aws_region
  cluster_name             = module.ecs.cluster_name
  service_name             = module.ecs.service_name
  alb_arn_suffix           = module.alb.alb_arn_suffix
  target_group_arn_suffix  = module.alb.target_group_arn_suffix
  tags                     = local.common_tags
}
