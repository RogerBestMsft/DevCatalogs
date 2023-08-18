
# resource "azurerm_resource_group" "rg" {
#   location = "eastus"
#   name     = "AAAAAAAlpha"
# }

data "azuread_client_config" "Current" {}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "MSGraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
} 

# data "azurerm_resource_group" "Environment" {
#   name = "${var.resource_group_name}"
# }

# resource "random_integer" "ResourceSuffix" {
# 	min 					= 10000
# 	max						= 99999
# }

# resource "azurerm_service_plan" "WebAppDemo" {
# 	name                	= "webappdemo${random_integer.ResourceSuffix.result}-plan"
# 	location            	= data.azurerm_resource_group.Environment.location
# 	resource_group_name 	= data.azurerm_resource_group.Environment.name

# 	os_type             	= "Windows"
# 	sku_name            	= "P1v2"
# }

# resource "azurerm_windows_web_app" "WebAppDemoWeb" {
# 	name                	= "webappdemo${random_integer.ResourceSuffix.result}-web"
# 	location            	= data.azurerm_resource_group.Environment.location
# 	resource_group_name 	= data.azurerm_resource_group.Environment.name
	
# 	service_plan_id 		= azurerm_service_plan.WebAppDemo.id
# 	https_only 				= true

#   site_config {}
# }

# resource "azuread_application" "WebAppDemoWebRegistry" {
# 	display_name 					= "${data.azurerm_resource_group.Environment.name}-${azurerm_windows_web_app.WebAppDemoWeb.default_hostname}"
# 	identifier_uris  				= [ "api://${data.azurerm_resource_group.Environment.name}-${azurerm_windows_web_app.WebAppDemoWeb.default_hostname}" ]
# 	owners 							= [ data.azuread_client_config.Current.object_id ]
# 	sign_in_audience 				= "AzureADMyOrg"

# 	web {
# 		homepage_url  = "https://${azurerm_windows_web_app.WebAppDemoWeb.default_hostname}"
# 		redirect_uris = ["https://${azurerm_windows_web_app.WebAppDemoWeb.default_hostname}/oauth2/callback/aad"]
# 	}
	
# 	required_resource_access {
# 		resource_app_id = "00000002-0000-0000-c000-000000000000"

# 		resource_access {
# 			id   = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
# 			type = "Scope"
# 		}

# 		resource_access {
# 			id   = "3afa6a7d-9b1a-42eb-948e-1650a849e176"
# 			type = "Scope"
# 		}
# 	}
# }