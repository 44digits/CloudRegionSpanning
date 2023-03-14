output "resource_group_name" {
  value = azurerm_resource_group.azure_rg.name
}

output "public_ip_address_server" {
  value = azurerm_linux_virtual_machine.server.public_ip_address
}

output "public_ip_address_proxy" {
  value = azurerm_linux_virtual_machine.proxy.public_ip_address
}

output "public_ip_client" {
  value       = aws_instance.aws-instance.public_dns
  description = "Public DNS hostname web server"
}

output "tls_privatekey_server" {
  value     = tls_private_key.server_ssh.private_key_pem
  sensitive = true
}

output "tls_privatekey_proxy" {
  value     = tls_private_key.proxy_ssh.private_key_pem
  sensitive = true
}
