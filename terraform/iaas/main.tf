terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

# Resource Group - créé s'il n'existe pas
resource "azurerm_resource_group" "target" {
  name     = var.resource_group_name
  location = "francecentral"
}

resource "random_string" "suffix" {
  length  = 4
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# Réseau
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${random_string.suffix.result}"
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-app"
  resource_group_name  = azurerm_resource_group.target.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_public_ip" "vm" {
  name                = "pip-vm-${random_string.suffix.result}"
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "vm" {
  name                = "nsg-vm-${random_string.suffix.result}"
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-${random_string.suffix.result}"
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# Lecture automatique des clés SSH depuis ~/.ssh/id_rsa.pub
locals {
  ssh_public_key_content = coalesce(
    var.ssh_public_key,
    try(file("${pathexpand("~")}/.ssh/id_rsa.pub"), "")
  )
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-app-${random_string.suffix.result}"
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name
  size                = var.vm_size

  admin_username = var.admin_username

  network_interface_ids = [azurerm_network_interface.vm.id]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.ssh_public_key_content
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

