variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type        = string
  description = "Location for all resources."
  default     = "eastus"
}

variable "project_resource_group_name" {
  type = string
  default = "VanArsdelLTD-Alpha-Dev-RG"
}

variable "project_virtual_network_name" {
  type = string
  default = "vanarsdelltdalphadevvnet"
}

variable "project_virtual_subnet_name" {
  type = string
  default = "sqlprivatesubnet"
}

variable "sql_resource_group_name" {
  type = string
  default = "VanArsdelLTD-Alpha-Dev-RG-Sql"
}

variable "sql_db_name" {
  type        = string
  description = "The name of the SQL Database."
  default     = "TestDBAlpha"
}

variable "sql_managed_instance_name" {
  type        = string
  description = "The name of the SQL Managed Instance."
  default     = "rbestecho"
}

variable "admin_username" {
  type        = string
  description = "The administrator username of the SQL logical server."
  default     = "azureadmin"
}

variable "admin_password" {
  type        = string
  description = "The administrator password of the SQL logical server."
  sensitive   = true
}