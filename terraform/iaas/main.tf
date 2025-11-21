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

  # Utilise l'abonnement actif d'Azure CLI si subscription_id n'est pas fourni
  subscription_id = var.subscription_id != "" ? var.subscription_id : null
}

# Data source pour récupérer le Resource Group s'il existe
data "azurerm_resource_group" "target" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

# Resource Group - créé seulement si create_resource_group est true
resource "azurerm_resource_group" "target" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = "francecentral"
}

# Local pour utiliser le RG existant ou créé
locals {
  resource_group = var.create_resource_group ? azurerm_resource_group.target[0] : data.azurerm_resource_group.target[0]
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
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-app"
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_public_ip" "vm" {
  name                = "pip-vm-${random_string.suffix.result}"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "vm" {
  name                = "nsg-vm-${random_string.suffix.result}"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

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
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

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
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
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

# Déploiement de l'application avec Ansible
resource "null_resource" "ansible_deploy" {
  depends_on = [
    azurerm_linux_virtual_machine.vm,
    azurerm_public_ip.vm
  ]

  triggers = {
    vm_id     = azurerm_linux_virtual_machine.vm.id
    public_ip = azurerm_public_ip.vm.ip_address
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -e
      
      # Chemins - utiliser le répertoire du module Terraform comme base
      SCRIPT_DIR="${path.module}"
      REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
      ANSIBLE_DIR=$REPO_ROOT/ansible
      PROJECT_PATH=$REPO_ROOT/sample-app-master
      DOCKER_COMPOSE_PATH=$REPO_ROOT/docker/docker-compose.yml
      
      # Variables
      VM_IP="${azurerm_public_ip.vm.ip_address}"
      VM_USER="${var.admin_username}"
      REMOTE_PATH="/opt/sample-app"
      
      # Gérer la clé SSH privée
      SSH_KEY_FILE=""
      SSH_KEY_TMP=""
      %{if var.ssh_private_key != ""~}
      # Créer un fichier de clé SSH temporaire depuis la variable
      SSH_KEY_TMP=$$(mktemp)
      cat > "$$SSH_KEY_TMP" <<'SSHKEY'
${var.ssh_private_key}
SSHKEY
      chmod 600 "$$SSH_KEY_TMP"
      SSH_KEY_FILE=$$SSH_KEY_TMP
      trap "rm -f $$SSH_KEY_TMP" EXIT
      %{else~}
      # Utiliser la clé SSH par défaut
      SSH_KEY_FILE="${pathexpand("~")}/.ssh/id_rsa"
      %{endif~}
      
      # Attendre que SSH soit disponible
      echo "Waiting for SSH to be available on $VM_IP..."
      for i in {1..30}; do
        if ssh -i "$SSH_KEY_FILE" \
               -o StrictHostKeyChecking=no \
               -o ConnectTimeout=5 \
               -o UserKnownHostsFile=/dev/null \
               "$VM_USER@$VM_IP" "echo 'SSH ready'" 2>/dev/null; then
          echo "SSH is ready!"
          break
        fi
        if [ $i -eq 30 ]; then
          echo "ERROR: SSH not available after 30 attempts"
          exit 1
        fi
        echo "Attempt $i/30: SSH not ready yet, waiting 10 seconds..."
        sleep 10
      done
      
      # Créer un inventaire Ansible temporaire
      INVENTORY_FILE=$(mktemp)
      cat > "$INVENTORY_FILE" <<EOF
[target]
vm ansible_host=$VM_IP ansible_user=$VM_USER ansible_ssh_private_key_file=$SSH_KEY_FILE ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF
      
      # Exécuter le playbook Ansible
      echo "Running Ansible playbook..."
      cd "$ANSIBLE_DIR"
      ANSIBLE_CONFIG="$ANSIBLE_DIR/ansible.cfg" \
      ansible-playbook \
        -i "$INVENTORY_FILE" \
        "$ANSIBLE_DIR/deploy.yml" \
        -e "local_project_path=$PROJECT_PATH" \
        -e "remote_project_path=$REMOTE_PATH" \
        -e "docker_compose_path=$DOCKER_COMPOSE_PATH" \
        -v
      
      # Nettoyer
      rm -f "$INVENTORY_FILE"
      if [ -n "$SSH_KEY_TMP" ]; then
        rm -f "$SSH_KEY_TMP"
      fi
    EOT

    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
      ANSIBLE_SSH_PIPELINING    = "True"
    }
  }
}

