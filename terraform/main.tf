terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}
# --- 1. NETWORK TOPOLOGY (VPC) ---
module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "5.8.1"
  name                 = "capstone-production-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
# --- 2. REGISTRY LAYER (ECR) ---
resource "aws_ecr_repository" "app_repo" {
  name                 = "springboot-app"
  image_tag_mutability = "MUTABLE"
  # Allows automatic deletion during teardown  force_destroy        = true             
  image_scanning_configuration {
    scan_on_push = true
  }
}
# --- 3. COMPUTE LAYER (EKS KUBERNETES) ---
module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "20.11.0"
  cluster_name                   = "dev-eks-cluster"
  cluster_version                = "1.30"
  cluster_endpoint_public_access = true
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  eks_managed_node_groups = {
    nodes = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["m7i-flex.large"]
      capacity_type  = "ON_DEMAND"
    }
  }
  # Grant cluster permissions to the AWS Web Console root login
  access_entries = {
    root_console_user = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::140023407747:root"
      type              = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}