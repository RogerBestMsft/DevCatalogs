terraform {
	required_providers {
		azurerm = {
			version = "=3.59.0"
		}
		azuread = {
			
		}
	}
}

provider "azurerm" {
	features {}
	skip_provider_registration = true
}


provisioner "remote-exec" {
    inline = [
      "chmod +x ${path.module}/EnsurePrivateDnsZoneB.sh",
      #"sudo /tmp/setup-lnxcfg-user",
    ]
  }

provisioner "remote-exec" {
    inline = [
      "chmod +x ${path.module}/InitSonarQubeB.sh",
      #"sudo /tmp/setup-lnxcfg-user",
    ]
  }
