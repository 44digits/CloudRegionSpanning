variable "project" {
  type        = string
  description = "Naming prefix for all resources"
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

