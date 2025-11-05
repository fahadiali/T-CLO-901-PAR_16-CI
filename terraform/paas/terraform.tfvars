# === Fill or keep defaults ===
resource_group_name = "rg-par_16"
prefix              = "terracloud"
plan_sku            = "B1"
acr_sku             = "Basic"
image_name          = "sample-app"
image_tag           = "latest"
container_port      = 80

# Example app settings (uncomment/adjust if needed)
# app_settings = {
#   APP_ENV = "production"
# }
