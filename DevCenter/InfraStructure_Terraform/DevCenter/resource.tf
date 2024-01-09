
data "azuread_client_config" "Current" {}

data "azuread_application_published_app_ids" "well_known" {}

# data "azuread_service_principal" "MSGraph" {
#   	client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
# } 

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
  for_each = toset(var.devcenter_object.environmentTypes)
  name = each.value
  parent_id = azapi_resource.devcenter.id
  body = jsonencode({
    properties = {}
  })
  depends_on = [ azapi_resource.devcenter ]
}

resource "azurerm_key_vault_secret" "devcenter_keyvault_repo_secret" {
    for_each = {for index, catalog in var.devcenter_catalogs: catalog.name => catalog}
    name = "${each.value.name}secret"
    value = each.value.repoAccess
    key_vault_id = azurerm_key_vault.devcenter_keyvault.id
    depends_on = [ azurerm_role_assignment.devcenter_keyvault_current_sp ]
}

resource "azapi_resource" "devcenter_catalog" {
  	type = "Microsoft.DevCenter/devcenters/catalogs@2023-04-01"
    for_each = { for index, catalog in var.devcenter_catalogs: catalog.name => catalog}
  	name = each.value.name
  	parent_id = azapi_resource.devcenter.id
  	body = jsonencode({
		properties = {
			gitHub = {
				branch = each.value.repoBranch
				path = each.value.repoPath
				secretIdentifier = azurerm_key_vault_secret.devcenter_keyvault_repo_secret[each.key].id
				uri = each.value.repoUri
			}
		}
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

output "azurerm_key_vault_secret" {
    value = [ for secret in azurerm_key_vault_secret.devcenter_keyvault_repo_secret : secret.id ]
}
