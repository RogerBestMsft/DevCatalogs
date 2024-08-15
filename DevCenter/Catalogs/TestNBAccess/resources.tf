# Generate a random integer to create a globally unique name
resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

# Get the resource group
data "azurerm_resource_group" "rg" {
  name = "${var.resource_group_name}"
}


