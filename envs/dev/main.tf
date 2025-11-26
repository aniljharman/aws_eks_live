########################
# VPC (private-focused)
########################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "dev-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-2a", "ap-south-2b", "ap-south-2c"]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
  public_subnets  = ["10.0.96.0/22", "10.0.100.0/22", "10.0.104.0/22"]

  enable_nat_gateway = true
  single_nat_gateway = true

  # Only ALBs/NLBs live in public subnets, no nodes
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  # Nodes + pods are only in private subnets
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Environment = "dev"
  }
}

########################
# EKS Cluster (private)
########################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "dev-eks"
  cluster_version = "1.30"

  # PRIVATE ONLY - B + C
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  # Small system nodegroup (Karpenter will handle main workloads later)
  eks_managed_node_groups = {
    system = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]

      labels = {
        "node-type" = "system"
      }

      tags = {
        "Name" = "dev-eks-system"
      }
    }
  }

  tags = {
    Environment = "dev"
  }
}

########################
# Outputs
########################

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "region" {
  value = "ap-south-2"
}
