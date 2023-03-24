##########################################################
#
#   Azure web server 
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


resource "azurerm_resource_group" "azure_rg" {
  location = var.azure_server_location
  name     = "${local.name_prefix}_azure_rg"
  tags     = local.common_tags
}

# Create virtual network
resource "azurerm_virtual_network" "server_network" {
  name                = "${local.name_prefix}_server_network"
  address_space       = ["10.0.0.0/16"]
  location            = var.azure_server_location
  resource_group_name = azurerm_resource_group.azure_rg.name
  tags                = local.common_tags
}

# Create subnet
resource "azurerm_subnet" "server_subnet" {
  name                 = "${local.name_prefix}_server_subnet"
  resource_group_name  = azurerm_resource_group.azure_rg.name
  virtual_network_name = azurerm_virtual_network.server_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "server_publicip" {
  name                = "${local.name_prefix}_server_publicip"
  location            = var.azure_server_location
  resource_group_name = azurerm_resource_group.azure_rg.name
  allocation_method   = "Dynamic"
  tags                = local.common_tags
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "server_nsg" {
  name                = "${local.name_prefix}_server_nsg"
  location            = var.azure_server_location
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
resource "azurerm_network_interface" "server_nic" {
  name                = "${local.name_prefix}_server_nic"
  location            = var.azure_server_location
  resource_group_name = azurerm_resource_group.azure_rg.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "${local.name_prefix}_server_nic-config"
    subnet_id                     = azurerm_subnet.server_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.server_publicip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "server_secgp" {
  network_interface_id      = azurerm_network_interface.server_nic.id
  network_security_group_id = azurerm_network_security_group.server_nsg.id
}

# Create (and display) an SSH key
resource "tls_private_key" "server_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "server_key" {
  content         = tls_private_key.server_ssh.private_key_pem
  filename        = "key/azure_server.pem"
  file_permission = "0600"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "server" {
  name                  = "${local.name_prefix}-server"
  location              = var.azure_server_location
  resource_group_name   = azurerm_resource_group.azure_rg.name
  network_interface_ids = [azurerm_network_interface.server_nic.id]
  size                  = var.azure_instance_type
  custom_data           = data.template_cloudinit_config.config_server.rendered
  tags                  = local.common_tags

  os_disk {
    name                 = "osDisk_server"
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
    public_key = tls_private_key.server_ssh.public_key_openssh
  }
}


resource "azurerm_virtual_network_peering" "server_proxy" {
  name                      = "server-proxy"
  resource_group_name       = azurerm_resource_group.azure_rg.name
  virtual_network_name      = azurerm_virtual_network.server_network.name
  remote_virtual_network_id = azurerm_virtual_network.proxy_network.id
}


