##########################################################
#
#   Azure vm
#     create azure vm with networking
#
##########################################################


##########################################################
# Variables
##########################################################

variable "vm_name" {
  description = "VM Name"
  type        = string
}

variable "vm_location" {
  description = "Region for vm"
  type        = string
}

variable "vm_resource_group_name" {
  description = "Resource group resource"
  type        = string
}

variable "vm_config" {
  description = "Resource group resource"
  type        = string
}

variable "tag_list" {
  description = "Resource tags"
  type        = map(any)
}

variable "vm_instance_type" {
  description = "Azure instance type"
  type        = string
}

variable "vm_address_range" {
  description = "CIDR block"
  type        = string
}



##########################################################
# Resources
##########################################################

# Create virtual network
resource "azurerm_virtual_network" "vm_network" {
  name                = "${var.vm_name}_network"
  address_space       = ["${var.vm_address_range}.0.0/16"]
  location            = var.vm_location
  resource_group_name = var.vm_resource_group_name
  tags                = var.tag_list
}

# Create subnet
resource "azurerm_subnet" "vm_subnet" {
  name                 = "${var.vm_name}_subnet"
  resource_group_name  = var.vm_resource_group_name
  virtual_network_name = azurerm_virtual_network.vm_network.name
  address_prefixes     = ["${var.vm_address_range}.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "vm_publicip" {
  name                = "${var.vm_name}_publicip"
  location            = var.vm_location
  resource_group_name = var.vm_resource_group_name
  allocation_method   = "Dynamic"
  tags                = var.tag_list
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.vm_name}_nsg"
  location            = var.vm_location
  resource_group_name = var.vm_resource_group_name
  tags                = var.tag_list

  security_rule {
    name                       = "icmp"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
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
resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.vm_name}_nic"
  location            = var.vm_location
  resource_group_name = var.vm_resource_group_name
  tags                = var.tag_list

  ip_configuration {
    name                          = "${var.vm_name}_nic-config"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_publicip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "vm_secgp" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# Create (and display) an SSH key
resource "tls_private_key" "vm_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = var.vm_name
  location              = var.vm_location
  resource_group_name   = var.vm_resource_group_name
  network_interface_ids = [azurerm_network_interface.vm_nic.id]
  size                  = var.vm_instance_type
  custom_data           = var.vm_config
  tags                  = var.tag_list

  os_disk {
    name                 = "${var.vm_name}_vmdisk"
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
    public_key = tls_private_key.vm_ssh.public_key_openssh
  }
}

##########################################################
# Outputs
##########################################################

output "vm" {
  value = azurerm_linux_virtual_machine.vm
}

output "ssh_key" {
  value = tls_private_key.vm_ssh.private_key_pem
}

output "virtual_network_name" {
  value = azurerm_virtual_network.vm_network.name
}

output "virtual_network_id" {
  value = azurerm_virtual_network.vm_network.id
}

output "private_ip" {
  value = azurerm_linux_virtual_machine.vm.private_ip_address
}
output "public_ip" {
  value = azurerm_linux_virtual_machine.vm.public_ip_address
}
