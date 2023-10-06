
data "azuread_client_config" "Current" {}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "MSGraph" {
  	application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
} 

data "azuread_user" "current_user" {
	object_id = data.azuread_client_config.Current.object_id
}

resource "random_integer" "ResourceSuffix" {
	min 					= 10000
	max						= 99999
}

resource "time_sleep" "wait_keyvault_rbac" {
  depends_on = [azurerm_key_vault.devcenter_keyvault]

  create_duration = "30s"
}

resource "time_sleep" "wait_gallery_rbac" {
  depends_on = [azurerm_shared_image_gallery.devcenter_gallery]

  create_duration = "30s"
}

resource "azurerm_resource_group" "devcenterRG" {
	#provider = azurerm.devcenter-sub
  	name     = var.devcenter_object.resourcegroup
  	location = var.devcenter_object.location
}

resource "azapi_resource" "devcenter" {
  	type = "Microsoft.DevCenter/devcenters@2023-04-01"
	parent_id = azurerm_resource_group.devcenterRG.id
  	name = var.devcenter_object.name
  	location = var.devcenter_object.location
  	identity {
    	type = var.devcenter_object.identity
  	}

}

resource "azurerm_key_vault" "devcenter_keyvault" {
	tenant_id 					= data.azuread_client_config.Current.tenant_id
  	name                        = var.devcenter_object.keyvault
  	location                    = var.devcenter_object.location
  	resource_group_name         = var.devcenter_object.resourcegroup
  	enabled_for_disk_encryption = true
  	soft_delete_retention_days  = 7
  	purge_protection_enabled    = false
	enable_rbac_authorization  	= true

	sku_name = "standard"
	depends_on = [ azurerm_resource_group.devcenterRG ]
}

resource "azurerm_role_assignment" "devcenter_keyvault_sp" {
  scope                = azurerm_key_vault.devcenter_keyvault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azapi_resource.devcenter.identity[0].principal_id
  depends_on = [time_sleep.wait_keyvault_rbac]
}

resource "azurerm_role_assignment" "devcenter_keyvault_current_sp" {
  scope                = azurerm_key_vault.devcenter_keyvault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azuread_user.current_user.object_id
  depends_on = [time_sleep.wait_keyvault_rbac]
}

resource "azurerm_key_vault_secret" "devcenter_keyvault_repo_secret" {
  name = var.devcenter_catalogs.name
  value = var.devcenter_catalogs.repoAccess
  key_vault_id = azurerm_key_vault.devcenter_keyvault.id
  depends_on = [ azurerm_role_assignment.devcenter_keyvault_current_sp ]
}

resource "azapi_resource" "devcenter_catalog" {
  	type = "Microsoft.DevCenter/devcenters/catalogs@2023-04-01"
  	name = var.devcenter_catalogs.name
  	parent_id = azapi_resource.devcenter.id
  	body = jsonencode({
		properties = {
			gitHub = {
				branch = var.devcenter_catalogs.repoBranch
				path = var.devcenter_catalogs.repoPath
				secretIdentifier = azurerm_key_vault_secret.devcenter_keyvault_repo_secret.id
				uri = var.devcenter_catalogs.repoUri
			}
		}
  	})
	depends_on = [ azapi_resource.devcenter ]
}


resource "azurerm_shared_image_gallery" "devcenter_gallery" {
  name                = var.devcenter_object.imagegallery
  resource_group_name = var.devcenter_object.resourcegroup
  location            = var.devcenter_object.location
  description         = "Shared images."
  depends_on = [ azurerm_resource_group.devcenterRG ]
}


resource "azurerm_role_assignment" "devcenter_gallery_sp" {
  scope                = azurerm_shared_image_gallery.devcenter_gallery.id
  role_definition_name = "Contributor"
  principal_id         = azapi_resource.devcenter.identity[0].principal_id
  depends_on = [time_sleep.wait_gallery_rbac]
}


resource "azapi_resource" "devcenter_gallery_attach" {
  type = "Microsoft.DevCenter/devcenters/galleries@2023-04-01"
  name = var.devcenter_object.imagegallery
  parent_id = azapi_resource.devcenter.id
  body = jsonencode({
    properties = {
      galleryResourceId = azurerm_shared_image_gallery.devcenter_gallery.id
    }
  })
  depends_on = [ azurerm_role_assignment.devcenter_gallery_sp ]
}

resource "azapi_resource" "devcenter_environment_types" {
  type = "Microsoft.DevCenter/devcenters/environmentTypes@2023-04-01"
  for_each = toset(var.devcenter_environment_types)
  name = each.value
  parent_id = azapi_resource.devcenter.id
  body = jsonencode({
    properties = {}
  })
  depends_on = [ azapi_resource.devcenter ]
}

resource "azapi_resource" "devcenter_devbox_definitions" {
	type = "Microsoft.DevCenter/devcenters/devboxdefinitions@2023-04-01"
	for_each = {
	  for index, definition in var.devcenter_devbox_definitions:
	  definition.name => definition
	}
	name = each.value.name
	parent_id = azapi_resource.devcenter.id
	location = each.value.location
	body = jsonencode({
		properties = {
			hibernateSupport = each.value.hibernate
			imageReference = {
				id = each.value.imageId				
			}
			osStorageType = each.value.storageType
			sku = {
				name = each.value.sku_Name
			}
		}
	})
	depends_on = [ azapi_resource.devcenter ]
}

# resource "azapi_resource" "devcenter_projects" {
#   type = "Microsoft.DevCenter/projects@2023-04-01"
#   for_each = {
# 	  for index, project in var.project_objects:
# 	  project.name => project
# 	}
#   name = each.value.name
#   location = each.value.location
#   parent_id = azapi_resource.devcenter.id
#   body = jsonencode({
#     properties = {
#       description = each.value.description
#       devCenterId = azapi_resource.devcenter.id
#       maxDevBoxesPerUser = each.value.maxDevBoxes
#     }
#   })
#   depends_on = [ azapi_resource.devcenter ]
# }

resource "azurerm_virtual_network" "devcenterVNet" {
  name                = "devcenternetwork"
  location            = azurerm_resource_group.devcenterRG.location
  resource_group_name = azurerm_resource_group.devcenterRG.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name           = "subnet1"
    address_prefix = "10.0.1.0/24"
  }

  subnet {
    name           = "subnet2"
    address_prefix = "10.0.2.0/24"
  }
}

resource "azapi_resource" "networkConnect" {
  type = "Microsoft.DevCenter/networkConnections@2023-04-01"
  name = "devcenternetconnect"
  location = azurerm_resource_group.devcenterRG.location
  parent_id = azurerm_resource_group.devcenterRG.id
  body = jsonencode({
    properties = {
      domainJoinType = "AzureADJoin"
      networkingResourceGroupName = "NI_terraform"
      subnetId = azurerm_virtual_network.devcenterVNet.subnet.*.id[0]
    }
  })
}

resource "azapi_resource" "devcenterNetConnect" {
  type = "Microsoft.DevCenter/devcenters/attachednetworks@2023-04-01"
  name = "devcenterconnection"
  parent_id = azapi_resource.devcenter.id
  body = jsonencode({
    properties = {
      networkConnectionId = azapi_resource.networkConnect.id
    }
  })
}