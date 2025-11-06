# Outputs Terraform pour le déploiement IaaS
output "public_ip" {
  description = "Adresse IP publique de la VM"
  value       = azurerm_public_ip.vm.ip_address
}

output "ssh_command" {
  description = "Commande SSH pratique pour se connecter à la VM"
  value       = "ssh -i <PATH_TO_PRIVATE_KEY> ${var.admin_username}@${azurerm_public_ip.vm.ip_address}"
}

