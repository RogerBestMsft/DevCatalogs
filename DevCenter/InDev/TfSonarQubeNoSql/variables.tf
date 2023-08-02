variable "resource_group_name" {
  type = string
}

variable "location" {
  default     = "eastus"
  description = "The location of the RG."
}

variable "siteName" {
  type = string
}

variable "sqlServerAdministratorUsername" {
  type = string
}

variable "sqlServerAdministratorPassword" {
  type = string
}