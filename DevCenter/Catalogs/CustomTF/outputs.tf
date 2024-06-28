output "resource_group_name" {
  value = data.azurerm_resource_group.EnvironmentRG.name
}

output "admin_password" {
  sensitive = true
  value     = var.admin_password
}