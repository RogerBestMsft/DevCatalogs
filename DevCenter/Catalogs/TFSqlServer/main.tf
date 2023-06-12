provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
}

data "azurerm_resource_group" "vnetrg" {
  name     = "NB_Demo"
}

# Vnet
data "azurerm_virtual_network" "rbest-vnet" {
    name = "NB_project_net"
    resource_group_name = data.azurerm_resource_group.vnetrg.name
}

data "azurerm_subnet" "rbest-sql-subnet" {
  name                 = "sqlsubnet"
  virtual_network_name = data.azurerm_virtual_network.rbest-vnet.name
  resource_group_name  = data.azurerm_virtual_network.rbest-vnet.resource_group_name
}

# Create a Private DNS Zone
resource "azurerm_private_dns_zone" "rbest-private-dns" {
  name = "rbestprivatedns.lan"
  resource_group_name = data.azurerm_resource_group.rg.name
  
}
# Link the Private DNS Zone with the VNET
resource "azurerm_private_dns_zone_virtual_network_link" "rbest-private-dns-link" {
  name = "rbest-vnet"
  resource_group_name = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.rbest-private-dns.name
  virtual_network_id = data.azurerm_virtual_network.rbest-vnet.id
}
# Create a DB Private DNS Zone
resource "azurerm_private_dns_zone" "rbest-endpoint-dns-private-zone" {
    #name = "rbestcharlie.zzz"
    name = "${azurerm_private_dns_zone_virtual_network_link.rbest-private-dns-link.name}.database.windows.net"
    #name = "privatelink.data.windows.net"
    resource_group_name = data.azurerm_resource_group.rg.name  
}

# sql private
# Create a DB Private Endpoint
resource "azurerm_private_endpoint" "rbest-db-endpoint" {
  depends_on = [azurerm_mssql_server.rbest-sql-server]
  name = "rbest-sql-db-endpoint"
  location = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id = data.azurerm_subnet.rbest-sql-subnet.id
  private_service_connection {
    name = "rbest-sql-db-endpoint"
    is_manual_connection = "false"
    private_connection_resource_id = azurerm_mssql_server.rbest-sql-server.id
    subresource_names = ["sqlServer"]
  }
}
# DB Private Endpoint Connecton
data "azurerm_private_endpoint_connection" "rbest-endpoint-connection" {
  depends_on = [azurerm_private_endpoint.rbest-db-endpoint]
  name = azurerm_private_endpoint.rbest-db-endpoint.name
  resource_group_name = data.azurerm_resource_group.rg.name
}
# Create a DB Private DNS A Record
resource "azurerm_private_dns_a_record" "rbest-endpoint-dns-a-record" {
  depends_on = [azurerm_mssql_server.rbest-sql-server]
  name = lower(azurerm_mssql_server.rbest-sql-server.name)
  zone_name = azurerm_private_dns_zone.rbest-endpoint-dns-private-zone.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl = 300
  records = [data.azurerm_private_endpoint_connection.rbest-endpoint-connection.private_service_connection.0.private_ip_address]
}
# Create a Private DNS to VNET link
resource "azurerm_private_dns_zone_virtual_network_link" "dns-zone-to-vnet-link" {
  name = "rbest-sql-db-vnet-link"
  resource_group_name = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.rbest-endpoint-dns-private-zone.name  
  virtual_network_id = data.azurerm_virtual_network.rbest-vnet.id
}

# resource "random_password" "admin_password" {
#   count       = var.admin_password == null ? 1 : 0
#   length      = 20
#   special     = true
#   min_numeric = 1
#   min_upper   = 1
#   min_lower   = 1
#   min_special = 1
# }

# locals {
#   admin_password = try(random_password.admin_password[0].result, var.admin_password)
# }

resource "azurerm_mssql_server" "rbest-sql-server" {
  name                         = "rbestsqlserver"
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password
  version                      = "12.0"
  public_network_access_enabled = false
}

resource "azurerm_mssql_database" "db" {
  depends_on = [azurerm_mssql_server.rbest-sql-server]
  name      = var.sql_db_name
  server_id = azurerm_mssql_server.rbest-sql-server.id
  collation = "Latin1_General_CI_AS"
  zone_redundant = false
  read_scale = false
}