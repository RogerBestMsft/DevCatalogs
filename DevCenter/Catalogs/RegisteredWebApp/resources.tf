data "azuread_client_config" "Current" {}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "MSGraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
} 

data "azurerm_resource_group" "Environment" {
  name = "${var.resource_group_name}"
}

resource "random_integer" "ResourceSuffix" {
	min 					= 10000
	max						= 99999
}

resource "azurerm_service_plan" "WebAppDemo" {
	name                	= "webappdemo${random_integer.ResourceSuffix.result}-plan"
	location            	= data.azurerm_resource_group.Environment.location
	resource_group_name 	= data.azurerm_resource_group.Environment.name

	os_type             	= "Windows"
	sku_name            	= "P1v2"
}