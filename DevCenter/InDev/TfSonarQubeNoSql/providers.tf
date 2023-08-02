terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      //version = "=3.0.2"
      version = "=3.50.0"
    }

    azapi = {
      source  = "azure/azapi"
      version = "=1.2.0"
    }
    


    
    kubernetes = {
      source = "hashicorp/kubernetes"
          
    }
    
  

    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 2.16.0"
    }


    

    azuread = {
      source  = "hashicorp/azuread"
     // version = "= 2.28.1"
     version = "2.30"
    }


    random = {
      source  = "hashicorp/random"
      version = "=3.1.2"
   // version = "3.0"
    }

  }
}