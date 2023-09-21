output "resource_group_name" {
  value = azurerm_resource_group.azure_rg.name
}

output "public_ip_address_server" {
  value = module.azure-server.public_ip
}

output "public_ip_address_proxy" {
  value = module.azure-proxy.public_ip
}

output "public_ip_client" {
  value       = aws_instance.aws-instance.public_dns
  description = "Public DNS hostname web server"
}
