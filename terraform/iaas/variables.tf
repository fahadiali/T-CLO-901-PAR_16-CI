# Variables Terraform pour le déploiement IaaS
# Configuration pour CI/CD avec GitHub Actions
# Test avec nouveaux credentials Azure
variable "resource_group_name" {
  description = "Nom du Resource Group existant où déployer la VM"
  type        = string
  default     = "rg-par_16"
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
  default     = "Standard_B1s"
}

