data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "random_string" "suffix" {
  length  = 4
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = replace("${var.prefix}acr${random_string.suffix.result}", "-", "")
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = coalesce(var.location, data.azurerm_resource_group.rg.location)
  sku                 = var.acr_sku
  admin_enabled       = true

  tags = {
    project     = var.prefix
    env         = "paas"
    cost_center = "student"
  }
}

# App Service Plan (Linux)
resource "azurerm_service_plan" "plan" {
  name                = "${var.prefix}-plan-${random_string.suffix.result}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = coalesce(var.location, data.azurerm_resource_group.rg.location)
  os_type             = "Linux"
  sku_name            = var.plan_sku

  tags = {
    project     = var.prefix
    env         = "paas"
    cost_center = "student"
  }
}

# Linux Web App (for Containers)
resource "azurerm_linux_web_app" "app" {
  name                = "${var.prefix}-web-${random_string.suffix.result}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = coalesce(var.location, data.azurerm_resource_group.rg.location)
  service_plan_id     = azurerm_service_plan.plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      docker_image     = "${azurerm_container_registry.acr.login_server}/${var.image_name}"
      docker_image_tag = var.image_tag
    }

    always_on = true

    # App Service listens on port 80; set WEBSITES_PORT to forward to your container port if different.
    application_stack {}
  }

  app_settings = merge({
    WEBSITES_PORT                       = tostring(var.container_port)
    DOCKER_REGISTRY_SERVER_URL          = "https://${azurerm_container_registry.acr.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.acr.admin_password
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITE_RUN_FROM_PACKAGE            = "0"
  }, var.app_settings)

  logs {
    detailed_error_messages = var.enable_system_logs
    failed_request_tracing  = var.enable_system_logs
    application_logs {
      file_system_level = "Information"
    }
    http_logs {
      file_system {
        retention_in_mb   = 100
        retention_in_days = 7
      }
    }
  }

  tags = {
    project     = var.prefix
    env         = "paas"
    cost_center = "student"
  }
}

# Allow Web App's managed identity to pull from ACR (AcrPull)
data "azurerm_subscription" "current" {}
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

output "webapp_name" {
  value = azurerm_linux_web_app.app.name
}

output "webapp_url" {
  value = azurerm_linux_web_app.app.default_hostname
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}
