# Terraform Provider
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0.2"
    }
  }
}

# Proveedor Azure AD
provider "azuread" {
  tenant_id = var.tenant_id
}

# Creamos la aplicación
resource "azuread_application" "tartuski" {
  display_name            = "tartuski"
  prevent_duplicate_names = true
}

# Agregamos una contraseña para la aplicación
resource "azuread_application_password" "tartuski" {
  application_id = azuread_application.tartuski.id
  display_name   = "Terraform-generated-password"
  end_date       = timeadd(timestamp(), "8760h") # 1 año
}

# Servicio Principal
resource "azuread_service_principal" "tartuski" {
  client_id      = azuread_application.tartuski.client_id
  description    = "Service Principal for ${azuread_application.tartuski.display_name}"
}

# Contraseña para Servicio Principal
resource "azuread_service_principal_password" "tartuski" {
  service_principal_id = azuread_service_principal.tartuski.id
  display_name         = "Terraform-generated-sp-password"
  end_date             = timeadd(timestamp(), "8760h") # 1 año
}

# Outputs
output "application_id" {
  value = azuread_application.tartuski.client_id
}

output "service_principal_id" {
  value = azuread_service_principal.tartuski.id
}

output "client_password" {
  value     = azuread_application_password.tartuski.value
  sensitive = true
}