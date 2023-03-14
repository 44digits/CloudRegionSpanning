##########################################################
#
#   Azure proxy server 
#
##########################################################


##########################################################
# Data
##########################################################


data "template_file" "proxy_tpl" {
  template = file("${path.module}/templates/proxy.tpl")
  vars = {
    server_privateip = "${azurerm_linux_virtual_machine.server.private_ip_address}"
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


# Create virtual network
resource "azurerm_virtual_network" "proxy_network" {
  name                = "${local.name_prefix}_proxy_network"
  address_space       = ["10.1.0.0/16"]
  location            = var.azure_proxy_location
  resource_group_name = azurerm_resource_group.azure_rg.name
  tags                = local.common_tags
}

# Create subnet
resource "azurerm_subnet" "proxy_subnet" {
  name                 = "${local.name_prefix}_proxy_subnet"
  resource_group_name  = azurerm_resource_group.azure_rg.name
  virtual_network_name = azurerm_virtual_network.proxy_network.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "proxy_publicip" {
  name                = "${local.name_prefix}_proxy_publicip"
  location            = var.azure_proxy_location
  resource_group_name = azurerm_resource_group.azure_rg.name
  allocation_method   = "Dynamic"
  tags                = local.common_tags
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "proxy_nsg" {
  name                = "${local.name_prefix}_proxy_nsg"
  location            = var.azure_proxy_location
  resource_group_name = azurerm_resource_group.azure_rg.name
  tags                = local.common_tags

  security_rule {
    name                       = "http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "SSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "proxy_nic" {
  name                = "${local.name_prefix}_proxy_nic"
  location            = var.azure_proxy_location
  resource_group_name = azurerm_resource_group.azure_rg.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "${local.name_prefix}_proxy_nic-config"
    subnet_id                     = azurerm_subnet.proxy_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.proxy_publicip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "proxy_secgp" {
  network_interface_id      = azurerm_network_interface.proxy_nic.id
  network_security_group_id = azurerm_network_security_group.proxy_nsg.id
}

# Create (and display) an SSH key
resource "tls_private_key" "proxy_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "proxy" {
  name                  = "${local.name_prefix}-proxy"
  location              = var.azure_proxy_location
  resource_group_name   = azurerm_resource_group.azure_rg.name
  network_interface_ids = [azurerm_network_interface.proxy_nic.id]
  size                  = var.azure_instance_type
  custom_data           = data.template_cloudinit_config.config_proxy.rendered
  tags                  = local.common_tags

  os_disk {
    name                 = "osDisk_proxy"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.proxy_ssh.public_key_openssh
  }
}


resource "azurerm_virtual_network_peering" "proxy_server" {
  name                      = "proxy-server"
  resource_group_name       = azurerm_resource_group.azure_rg.name
  virtual_network_name      = azurerm_virtual_network.proxy_network.name
  remote_virtual_network_id = azurerm_virtual_network.server_network.id
}
