variable "project" {
  type        = string
  description = "Naming prefix for all resources"
}

variable "aws_client_region" {
  type        = string
  description = "AWS Region to use for client"
}

variable "aws_instance_type" {
  type        = string
  description = "Type for EC2 Instnace"
}

variable "azure_instance_type" {
  type        = string
  description = "Type of Azure instance, server & proxy"
}

variable "azure_server_location" {
  type        = string
  description = "Region for server"
}

variable "azure_proxy_location" {
  type        = string
  description = "Region for proxy"
}

