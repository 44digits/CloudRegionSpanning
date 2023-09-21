
##########################################################
#
#   Azure web server & proxy
#
##########################################################


##########################################################
# Data
##########################################################


data "template_file" "server_tpl" {
  template = file("${path.module}/templates/server.tpl")
  vars = {
    project_name = "${local.name_prefix}"
  }
}


data "template_cloudinit_config" "config_server" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.server_tpl.rendered
  }
}


data "template_file" "proxy_tpl" {
  template = file("${path.module}/templates/proxy.tpl")
  vars = {
    server_privateip = "${module.azure-server.private_ip}"
  }
}


data "template_cloudinit_config" "config_proxy" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.proxy_tpl.rendered
  }
}


##########################################################
# Resources
##########################################################

resource "azurerm_resource_group" "azure_rg" {
  location = var.azure_server_location
  name     = "${local.name_prefix}_azure_rg"
  tags     = local.common_tags
}

module "azure-server" {
  source = "./azure-vm"

  vm_name                = "${local.name_prefix}-server"
  vm_location            = var.azure_server_location
  vm_resource_group_name = azurerm_resource_group.azure_rg.name
  vm_config              = data.template_cloudinit_config.config_server.rendered
  vm_instance_type       = var.azure_instance_type
  vm_address_range       = "10.0"
  tag_list               = local.common_tags
}

resource "local_file" "server_key" {
  content         = module.azure-server.ssh_key
  filename        = "key/azure_server.pem"
  file_permission = "0600"
}

module "azure-proxy" {
  source = "./azure-vm"

  vm_name                = "${local.name_prefix}-proxy"
  vm_location            = var.azure_proxy_location
  vm_resource_group_name = azurerm_resource_group.azure_rg.name
  vm_config              = data.template_cloudinit_config.config_proxy.rendered
  vm_instance_type       = var.azure_instance_type
  vm_address_range       = "10.1"
  tag_list               = local.common_tags
}

resource "local_file" "proxy_key" {
  content         = module.azure-proxy.ssh_key
  filename        = "key/azure_proxy.pem"
  file_permission = "0600"
}

resource "azurerm_virtual_network_peering" "server_proxy" {
  name                      = "server-proxy"
  resource_group_name       = azurerm_resource_group.azure_rg.name
  virtual_network_name      = module.azure-server.virtual_network_name
  remote_virtual_network_id = module.azure-proxy.virtual_network_id
}

resource "azurerm_virtual_network_peering" "proxy_server" {
  name                      = "proxy-server"
  resource_group_name       = azurerm_resource_group.azure_rg.name
  virtual_network_name      = module.azure-proxy.virtual_network_name
  remote_virtual_network_id = module.azure-server.virtual_network_id
}


