param location string = resourceGroup().location

@description('The resource ID of the DevCenter.')
param devCenterId string

@description('Networking object')
param vnetObject object = {}

@description('Tags to apply to the resources')
param tags object = {}

var devCenterName = empty(devCenterId) ? 'devCenterName' : last(split(devCenterId, '/'))
var devCenterGroup = empty(devCenterId) ? '' : first(split(last(split(replace(devCenterId, 'resourceGroups', 'resourcegroups'), '/resourcegroups/')), '/'))
var devCenterSub = empty(devCenterId) ? '' : first(split(last(split(devCenterId, '/subscriptions/')), '/'))

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: vnetObject.name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: vnetObject.ipRanges
    }
    subnets: [for subnet in vnetObject.subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.iprange
      }
    }]
  }
}

resource networkConnection 'Microsoft.DevCenter/networkConnections@2023-01-01-preview' = if (vnetObject.domainjoinType != 'None') {
  name: 'conn${vnetObject.name}'
  location: location
  properties: {
    subnetId: '${vnet.id}/subnets/${vnetObject.subnets[0].name}'
    networkingResourceGroupName: '${vnetObject.name}-ni'
    domainJoinType: vnetObject.domainjoinType
  }
  tags: tags
}

// If a devcenter resource id was provided attach the nc to the devcenter
module networkAttach 'networkAttach.bicep' = if ((!empty(devCenterId)) && (vnetObject.domainjoinType != 'None')) {
  scope: resourceGroup(devCenterSub, devCenterGroup)
  name: 'conn${vnetObject.name}-attach'
  params: {
    #disable-next-line BCP335
    name: networkConnection.name
    devCenterName: devCenterName
    #disable-next-line BCP334
    networkConnectionId: networkConnection.id
  }
}

output networkconnection string = networkConnection.name
