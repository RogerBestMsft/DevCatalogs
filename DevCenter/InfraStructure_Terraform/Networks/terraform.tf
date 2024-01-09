terraform {
	required_providers {
		azurerm = {

		}
		azuread = {
			
		}
		azapi = {
			source = "azure/azapi"
		}
	}
}

provider "azapi" {
  
}

provider "azurerm" {
	features {}
}

provider "azuread" {
  
}

# provider "azurerm" {
# 	alias = "devcenter-sub"
# 	subscription_id = ""
# 	features {}
# 	skip_provider_registration = true
# }

# provider "azurerm" {
# 	alias = "project-sub"
# 	subscription_id = ""
# 	features {}
# 	skip_provider_registration = true
# }