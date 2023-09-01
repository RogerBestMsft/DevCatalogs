data "azuread_client_config" "Current" {}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "MSGraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
} 

data "azurerm_resource_group" "EnvironmentRG" {
  name = "${var.resource_group_name}"
}

data "azurerm_resource_group" "ProjectRG" {
  name = "${var.project_resource_group_name}"
}

data "azurerm_resource_group" "SqlInstRG" {
  name = "${var.sql_resource_group_name}"
}

data "azurerm_virtual_network" "project-vnet" {
  name = "${var.project_virtual_network_name}"
  resource_group_name = data.azurerm_resource_group.ProjectRG.name
}

data "azurerm_subnet" "endpoint-subnet" {
  name = "${var.project_virtual_subnet_name}"
  virtual_network_name = data.azurerm_virtual_network.project-vnet.name
  resource_group_name = data.azurerm_resource_group.ProjectRG.name
}

resource "random_integer" "ResourceSuffix" {
	min 					= 10000
	max						= 99999
}

data "azurerm_mssql_managed_instance" "primary-sql-server" {
  name                         = "${var.sql_managed_instance_name}"
  resource_group_name          = data.azurerm_resource_group.SqlInstRG.name
}

resource "azurerm_mssql_managed_database" "db" {
  depends_on = [data.azurerm_mssql_managed_instance.primary-sql-server]
  name      = var.sql_db_name
  managed_instance_id = data.azurerm_mssql_managed_instance.primary-sql-server.id
}

resource "azurerm_service_plan" "WebAppDemo" {
	name                	= "webappsqldemo${random_integer.ResourceSuffix.result}-plan"
	location            	= data.azurerm_resource_group.EnvironmentRG.location
	resource_group_name 	= data.azurerm_resource_group.EnvironmentRG.name

	os_type             	= "Windows"
	sku_name            	= "P1v2"
}

resource "azurerm_windows_web_app" "WebAppDemoWeb" {
	name                	= "webappsqldemo${random_integer.ResourceSuffix.result}-web"
	location            	= data.azurerm_resource_group.EnvironmentRG.location
	resource_group_name 	= data.azurerm_resource_group.EnvironmentRG.name
	
	service_plan_id 		= azurerm_service_plan.WebAppDemo.id
	https_only 				= true

  site_config {}
}

resource "azurerm_private_dns_zone" "webdnsprivatezone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = data.azurerm_resource_group.EnvironmentRG.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszonelink" {
  name = "dnszonelink"
  resource_group_name = data.azurerm_resource_group.EnvironmentRG.name
  private_dns_zone_name = azurerm_private_dns_zone.webdnsprivatezone.name
  virtual_network_id = data.azurerm_virtual_network.project-vnet.id
}

resource "azurerm_private_endpoint" "webprivateendpoint" {
  name                = "webappprivateendpoint"
  location            = data.azurerm_resource_group.EnvironmentRG.location
  resource_group_name = data.azurerm_resource_group.EnvironmentRG.name
  subnet_id           = data.azurerm_subnet.endpoint-subnet.id

  private_dns_zone_group {
    name = "privatednszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.webdnsprivatezone.id]
  }

  private_service_connection {
    name = "privateendpointconnection"
    private_connection_resource_id = azurerm_windows_web_app.WebAppDemoWeb.id
    subresource_names = ["sites"]
    is_manual_connection = false
  }
}

resource "azuread_application" "WebAppSqlDemoWebRegistry" {
	display_name 					= "${data.azurerm_resource_group.EnvironmentRG.name}-${azurerm_windows_web_app.WebAppDemoWeb.default_hostname}"
	identifier_uris  				= [ "api://${data.azurerm_resource_group.EnvironmentRG.name}-${azurerm_windows_web_app.WebAppDemoWeb.default_hostname}" ]
	owners 							= [ data.azuread_client_config.Current.object_id ]
	sign_in_audience 				= "AzureADMyOrg"

	web {
		homepage_url  = "https://${azurerm_windows_web_app.WebAppDemoWeb.default_hostname}"
		redirect_uris = ["https://${azurerm_windows_web_app.WebAppDemoWeb.default_hostname}/oauth2/callback/aad"]
	}
	
	required_resource_access {
		resource_app_id = "00000002-0000-0000-c000-000000000000"

		resource_access {
			id   = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
			type = "Scope"
		}

		resource_access {
			id   = "3afa6a7d-9b1a-42eb-948e-1650a849e176"
			type = "Scope"
		}
	}
}