data "azurerm_resource_group" "Environment" {
  name = "${var.resource_group_name}"
}

resource "random_integer" "ResourceSuffix" {
	min 					= 10000
	max						= 99999
}

# Vnet
data "azurerm_virtual_network" "primary-vnet" {
  name = "primaryvnet${random_integer.ResourceSuffix.result}"
  resource_group_name = data.azurerm_resource_group.Environment.name
}

data "azurerm_subnet" "sql-subnet" {
  name                 = "sqlsubnet"
  virtual_network_name = data.azurerm_virtual_network.primary-vnet.name
  resource_group_name  = data.azurerm_resource_group.Environment.name
}

resource "azurerm_mssql_server" "primary-sql-server" {
  name                         = "primaryserver${random_integer.ResourceSuffix.result}"
  resource_group_name          = data.azurerm_resource_group.Environment.name
  location                     = data.azurerm_resource_group.Environment.location
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password
  version                      = "12.0"
  public_network_access_enabled = false
}

resource "azurerm_mssql_database" "db" {
  depends_on = [azurerm_mssql_server.primary-sql-server]
  name      = var.database_name
  server_id = azurerm_mssql_server.rbest-sql-server.id
  collation = "Latin1_General_CI_AS"
  zone_redundant = false
  read_scale = false
}

# # Create a DB Private DNS Zone
# resource "azurerm_private_dns_zone" "rbest-endpoint-dns-private-zone" {
#     #name = "${azurerm_private_dns_zone_virtual_network_link.rbest-endpoint-dns-link.name}.database.windows.net"
#     name = "privatelink.database.windows.net"
#     resource_group_name = data.azurerm_resource_group.sqlrg.name  
# }

# # Link the Private DNS Zone with the VNET
# resource "azurerm_private_dns_zone_virtual_network_link" "rbest-endpoint-dns-link" {
#   name = "rbest-vnet"
#   resource_group_name = data.azurerm_resource_group.sqlrg.name
#   private_dns_zone_name = azurerm_private_dns_zone.rbest-endpoint-dns-private-zone.name
#   virtual_network_id = data.azurerm_virtual_network.rbest-vnet.id
# }

# # DB Private Endpoint Connecton
# data "azurerm_private_endpoint_connection" "rbest-endpoint-connection" {
#   depends_on = [azurerm_private_endpoint.rbest-db-endpoint]
#   name = azurerm_private_endpoint.rbest-db-endpoint.name
#   resource_group_name = data.azurerm_resource_group.sqlrg.name
# }

# Create a DB Private DNS A Record
# resource "azurerm_private_dns_a_record" "rbest-endpoint-dns-a-record" {
#   depends_on = [azurerm_mssql_server.rbest-sql-server]
#   name = lower(azurerm_mssql_server.rbest-sql-server.name)
#   zone_name = azurerm_private_dns_zone.rbest-endpoint-dns-private-zone.name
#   resource_group_name = data.azurerm_resource_group.sqlrg.name
#   ttl = 300
#   records = [data.azurerm_private_endpoint_connection.rbest-endpoint-connection.private_service_connection.0.private_ip_address]
# }

# # Create a Private DNS to VNET link
# resource "azurerm_private_dns_zone_virtual_network_link" "dns-zone-to-vnet-link" {
#   name = "rbest-sql-db-vnet-link"
#   resource_group_name = data.azurerm_resource_group.vnetrg.name
#   private_dns_zone_name = azurerm_private_dns_zone.rbest-endpoint-dns-private-zone.name  
#   virtual_network_id = data.azurerm_virtual_network.rbest-vnet.id
# }

# locals {
#   admin_password = try(random_password.admin_password[0].result, var.admin_password)
# }

# Create a DB Private Endpoint
# resource "azurerm_private_endpoint" "rbest-db-endpoint" {
#   depends_on = [
#     azurerm_mssql_server.rbest-sql-server,
#     azurerm_private_dns_zone.rbest-endpoint-dns-private-zone
#     ]
#   name = "rbest-sql-db-endpoint"
#   location = data.azurerm_resource_group.sqlrg.location
#   resource_group_name = data.azurerm_resource_group.sqlrg.name
#   subnet_id = data.azurerm_subnet.rbest-sql-subnet.id
#   private_service_connection {
#     name = "rbest-sql-db-endpoint"
#     is_manual_connection = "false"
#     private_connection_resource_id = azurerm_mssql_server.rbest-sql-server.id
#     subresource_names = ["sqlServer"]
#   }
#   private_dns_zone_group {
#     name                 = azurerm_private_dns_zone.rbest-endpoint-dns-private-zone.name
#     private_dns_zone_ids = [azurerm_private_dns_zone.rbest-endpoint-dns-private-zone.id]
#   }
# }