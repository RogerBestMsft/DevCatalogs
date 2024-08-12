terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.60.0"      
    }
  
    azapi = {
      source  = "azure/azapi"
      version = "~>1.2.0"
    }
   
    azuread = {
      source  = "hashicorp/azuread"
     // version = "= 2.28.1"
     version = "~>2.30"
    }


    random = {
      source  = "hashicorp/random"
      version = "~>3.5.1"
   // version = "3.0"
    }

  }
}