
data "azuread_client_config" "Current" {}

data "azuread_application_published_app_ids" "well_known" {}

data "azurerm_resource_group" "Environment" {
  name = "${var.resource_group_name}"
}

resource "random_integer" "ResourceSuffix" {
	min 					= 10000
	max						= 99999
}

resource "terraform_data" "checktoken" {
  provisioner "local-exec" {
    command = "./ade/repository/DevCenter/Catalogs/Catalogs/TestNBAccess/CheckToken.sh"
  }
}
