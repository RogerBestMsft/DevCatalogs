output "resource_group_name" {
  value = data.azurerm_resource_group.sqlrg.name
}

output "sql_server_name" {
  value = azurerm_mssql_server.rbest-sql-server.fully_qualified_domain_name
}

output "admin_password" {
  sensitive = true
  value     = var.admin_password
}