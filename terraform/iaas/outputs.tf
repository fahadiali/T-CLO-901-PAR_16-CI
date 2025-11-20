# Outputs Terraform pour le déploiement IaaS
# Redéploiement après nettoyage du resource group
output "public_ip" {
  description = "Adresse IP publique de la VM"
  value       = azurerm_public_ip.vm.ip_address
}

output "ssh_command" {
  description = "Commande SSH pratique pour se connecter à la VM"
  value       = "ssh -i ~/.ssh/id_rsa ${var.admin_username}@${azurerm_public_ip.vm.ip_address}"
}

