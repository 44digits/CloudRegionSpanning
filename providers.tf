terraform {
  required_version = ">=0.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source = "hashicorp/random"
      #version = "~>3.0"
    }
    tls = {
      source = "hashicorp/tls"
      #version = "~>4.0"
    }
    cloudinit = {
      source = "hashicorp/cloudinit"
      #version = "~>2.0"
    }
  }
}

provider "aws" {
  region = var.aws_client_region
}

provider "azurerm" {
  features {}
}

