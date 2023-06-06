# Configure the Azure provider
# terraform {
#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = "~> 3.0.0"
#     }
#   }
#   required_version = ">= 0.14.9"
# }

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# Generate a random integer to create a globally unique name
resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

# Create the resource group
# resource "azurerm_resource_group" "rg" {
#  name     = "myResourceGroup-${random_integer.ri.result}"
#  location = "eastus"
#}

# Create the Linux App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  name                = "webapp-asp-${random_integer.ri.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "webapp" {
  name                  = var.siteName
  location              = var.location
  resource_group_name   = var.resource_group_name
  service_plan_id       = azurerm_service_plan.appserviceplan.id
  https_only            = true
  site_config { 
    minimum_tls_version = "1.2"
    SONARQUBE_JDBC_URL = "jdbc:sqlserver://deltarbest-sql.database.windows.net:1433;database=sonarqube;user=roger@deltarbest-sql;password={your_password_here};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30jdbc:sqlserver://deltarbest-sql.database.windows.net:1433;database=sonarqube;user=roger@deltarbest-sql;password=" + var.sqlServerAdministratorPassword + ";encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"
    SONARQUBE_JDBC_USERNAME = var.qlServerAdministratorUsername
    SONARQUBE_JDBC_PASSWORD = var.sqlServerAdministratorPassword
    sonar_path_data = "/home/sonarqube/data"
  }
}
