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
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group existant
data "azurerm_resource_group" "target" {
  name = var.resource_group_name
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
  location            = data.azurerm_resource_group.target.location
  resource_group_name = data.azurerm_resource_group.target.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-app"
  resource_group_name  = data.azurerm_resource_group.target.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_public_ip" "vm" {
  name                = "pip-vm-${random_string.suffix.result}"
  location            = data.azurerm_resource_group.target.location
  resource_group_name = data.azurerm_resource_group.target.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "vm" {
  name                = "nsg-vm-${random_string.suffix.result}"
  location            = data.azurerm_resource_group.target.location
  resource_group_name = data.azurerm_resource_group.target.name

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
  location            = data.azurerm_resource_group.target.location
  resource_group_name = data.azurerm_resource_group.target.name

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

# Lecture automatique des clés SSH depuis ~/.ssh/id_rsa.pub et ~/.ssh/id_rsa
locals {
  ssh_public_key_content = coalesce(
    var.ssh_public_key,
    try(file("${pathexpand("~")}/.ssh/id_rsa.pub"), "")
  )
  ssh_private_key_content = coalesce(
    var.ssh_private_key,
    try(file("${pathexpand("~")}/.ssh/id_rsa"), "")
  )

  cloud_init = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - ca-certificates
      - curl
      - gnupg
    runcmd:
      - |
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        . /etc/os-release
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" > /etc/apt/sources.list.d/docker.list
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      - usermod -aG docker ${var.admin_username}
      - systemctl enable docker
      - systemctl start docker
      - mkdir -p /opt/app
  EOF
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-app-${random_string.suffix.result}"
  location            = data.azurerm_resource_group.target.location
  resource_group_name = data.azurerm_resource_group.target.name
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
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(local.cloud_init)
}

resource "null_resource" "deploy_app" {
  depends_on = [azurerm_linux_virtual_machine.vm]

  triggers = {
    compose_hash = filemd5("${path.module}/../../docker/docker-compose.yml")
  }

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.vm.ip_address
    user        = var.admin_username
    private_key = local.ssh_private_key_content
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/app",
      "sudo chown ${var.admin_username}:${var.admin_username} /opt/app",
      "sudo rm -rf /opt/app/sample-app-master"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/../../docker/docker-compose.yml"
    destination = "/opt/app/docker-compose.yml"
  }

  provisioner "file" {
    source      = "${path.module}/../../sample-app-master"
    destination = "/opt/app/sample-app-master"
  }

  provisioner "file" {
    content     = file("${path.module}/env.tpl")
    destination = "/opt/app/sample-app-master/.env"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Attente de l installation de Docker...'",
      "for i in {1..30}; do",
      "  if command -v docker >/dev/null 2>&1 && docker --version >/dev/null 2>&1; then",
      "    echo 'Docker est installé et prêt'",
      "    break",
      "  fi",
      "  echo 'Tentative $i/30: Docker pas encore prêt, attente 10 secondes...'",
      "  sleep 10",
      "done",
      "if ! command -v docker >/dev/null 2>&1; then",
      "  echo 'ERREUR: Docker n est pas installé après 5 minutes'",
      "  exit 1",
      "fi",
      "cd /opt/app && sudo docker compose build",
      "cd /opt/app && sudo docker compose up -d"
    ]
  }
}

