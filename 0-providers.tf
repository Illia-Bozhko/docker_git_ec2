variable aws_access_key_id {
    description = "aws_access_key_id"
}

variable secret_access_key_id {
    description = "secret_access_key_id"
}


provider "aws" {
    region = "ap-south-1"
    access_key = var.aws_access_key_id
    secret_key = var.secret_access_key_id
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.6.0"
    }
  }

  required_version = "~> 1.0"
}