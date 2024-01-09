resource "azurerm_resource_group" "devcenter_network_RGs" {
	for_each = var.devcenter_project_networks
    name                = each.value.resource_group_name
  	location            = each.value.location
}

resource "azurerm_virtual_network" "devcenter_project_vnets" {
  for_each = var.devcenter_project_networks
    name = each.key
    location = each.value.location
    resource_group_name = each.value.resource_group_name
    address_space = each.value.cidr_block
    depends_on = [ azurerm_resource_group.devcenter_network_RGs ]
}

locals {
  # flatten ensures that this local value is a flat list of objects, rather
  # than a list of lists of objects.
  network_subnets = flatten([
    for network_key, network in var.devcenter_project_networks : [
      for subnet_key, subnet in network.subnets : {
        network_key = network_key
        subnet_key  = subnet_key
        rg_name  = network.resource_group_name
        cidr_block  = subnet.cidr_block
      }
    ]
  ])
}

resource "azurerm_subnet" "devcenter_project_subnets" {
    # local.network_subnets is a list, so we must now project it into a map
    # where each key is unique. We'll combine the network and subnet keys to
    # produce a single unique key per instance.
    for_each = {
        for subnet in local.network_subnets : "${subnet.network_key}.${subnet.subnet_key}" => subnet
    }

    name                    = each.value.subnet_key
    resource_group_name     = each.value.rg_name
    virtual_network_name    = each.value.network_key
    address_prefixes        = each.value.cidr_block
    depends_on = [ azurerm_virtual_network.devcenter_project_vnets ]
}

resource "azapi_resource" "devcenter_project_networkConnect" {
  type = "Microsoft.DevCenter/networkConnections@2023-04-01"
  for_each = var.devcenter_project_networks
    name = each.key
    location = each.value.location
    parent_id = azurerm_resource_group.devcenterRG.id
    body = jsonencode({
        properties = {
        domainJoinType = "AzureADJoin"
        networkingResourceGroupName = "NI_terraform"
        subnetId = azurerm_virtual_network.devcenterVNet.subnet.*.id[0]
        }
    })
}

# resource "azapi_resource" "devcenterNetConnect" {
#   type = "Microsoft.DevCenter/devcenters/attachednetworks@2023-04-01"
#   name = "devcenterconnection"
#   parent_id = azapi_resource.devcenter.id
#   body = jsonencode({
#     properties = {
#       networkConnectionId = azapi_resource.networkConnect.id
#     }
#   })
# }
