# Variables Terraform pour le déploiement IaaS
# Configuration pour CI/CD avec GitHub Actions
# Test avec nouveaux credentials Azure
# Resource group dans francecentral
# Connexion Azure CLI directe
# Permissions Service Principal ajoutées
# Relance CI après nettoyage
variable "resource_group_name" {
  description = "Nom du Resource Group où déployer la VM"
  type        = string
  default     = "rg-par_16"
}

variable "create_resource_group" {
  description = "Créer le Resource Group s'il n'existe pas. Si false, utilise un Resource Group existant."
  type        = bool
  default     = false
}

variable "admin_username" {
  description = "Nom d'utilisateur administrateur pour la VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Clé publique SSH pour accès à la VM"
  type        = string
  default     = ""
}

variable "ssh_private_key" {
  description = "Clé privée SSH pour les provisioners"
  type        = string
  default     = ""
  sensitive   = true
}

variable "vm_size" {
  description = "Taille de la VM Azure"
  type        = string
  default     = "Standard_B2ms"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID. Si non spécifié, utilise l'abonnement actif d'Azure CLI."
  default     = ""
}
