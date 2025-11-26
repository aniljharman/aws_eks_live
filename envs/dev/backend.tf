terraform {
  backend "s3" {
    bucket = "ajose-amzn-terraform-state"
    key    = "aws_eks_live/dev/terraform.tfstate"
    region = "ap-south-2"
    encrypt = true
  }
}