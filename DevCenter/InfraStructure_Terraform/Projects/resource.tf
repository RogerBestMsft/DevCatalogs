
resource "random_integer" "ResourceSuffix" {
	min 					= 10000
	max						= 99999
}

resource "azurerm_resource_group" "projectRG" {
  	for_each = {
	  for index, project in var.project_object:
	  project.name => project
	}
  	name     = each.value.resourcegroup
  	location = each.value.location
}

resource "azapi_resource" "devcenter_projects" {
	type = "Microsoft.DevCenter/projects@2023-04-01"
	for_each = {
	  for index, project in var.project_object:
	  project.name => project
	}
	name = each.value.name
	parent_id = each.value.devCenterId
	location = each.value.location
	body = jsonencode({
		properties = {
			description = each.value.description
			devCenterId = each.value.devCenterId
            maxDevBoxesPerUser = each.value.devboxLimits            
		}
	})
}


# resource "azapi_resource" "project_environment_types" {
#     type = "Microsoft.DevCenter/projects/environmentTypes@2023-10-01-preview"
# 	for_each = {
# 	  for index, project in var.project_object:
# 	  project.environmentTypes => project
# 	}
#     name = each.value.name
#     location = each.value.location
#     parent_id = each.value.

# }