variable "resource_group_name" {
  description = "Existing Azure Resource Group for PaaS resources"
  type        = string
  default     = "rg-par_16"
}

variable "prefix" {
  description = "Naming prefix for resources"
  type        = string
  default     = "terracloud"
}

variable "location" {
  description = "Azure location (inferred from RG if left empty)"
  type        = string
  default     = ""
}

variable "plan_sku" {
  description = "App Service Plan SKU (e.g., B1, P1v3)"
  type        = string
  default     = "B1"
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"
}

variable "image_name" {
  description = "Repository name in ACR (e.g., sample-app)"
  type        = string
  default     = "sample-app"
}

variable "image_tag" {
  description = "Tag for the container image"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Exposed port of the container serving HTTP"
  type        = number
  default     = 80
}

variable "app_settings" {
  description = "Extra App Settings (key/value)"
  type        = map(string)
  default     = {}
}

variable "enable_system_logs" {
  description = "Enable diagnostic logs for the Web App"
  type        = bool
  default     = true
}
