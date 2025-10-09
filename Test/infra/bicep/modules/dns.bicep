/*
  Defines Private DNS Zones for the WinGit application
  - Creates private DNS zones for Storage Account and Redis Cache
  - Links DNS zones to VNet for name resolution
  - Only deploys when private endpoints are enabled
*/

targetScope = 'resourceGroup'

@description('Configuration object containing solution settings')
param config object

@description('Virtual Network ID for DNS zone linking')
param vnetId string

@description('Whether networking resources should be deployed')
param shouldDeployNetworking bool

// Get environment-specific storage and Redis endpoints
var storageEndpoint = environment().suffixes.storage
var redisEndpoint = 'redis.cache.windows.net' // Redis doesn't have environment-specific endpoint

/*
  Private DNS Zone for Storage Account (Blob service)
*/
resource storageBlobDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (shouldDeployNetworking) {
  name: 'privatelink.blob.${storageEndpoint}'
  location: 'global'
  properties: {}
}

/*
  Private DNS Zone for Redis Cache
*/
resource redisDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (shouldDeployNetworking) {
  name: 'privatelink.${redisEndpoint}'
  location: 'global'
  properties: {}
}

/*
  Link Storage Blob DNS Zone to VNet
*/
resource storageBlobDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (shouldDeployNetworking) {
  name: 'link-${config.solutionName}-storage'
  parent: storageBlobDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

/*
  Link Redis DNS Zone to VNet
*/
resource redisDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (shouldDeployNetworking) {
  name: 'link-${config.solutionName}-redis'
  parent: redisDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

/*
  Outputs for use by other modules
*/
output storageBlobDnsZoneId string = shouldDeployNetworking ? storageBlobDnsZone.id : ''
output redisDnsZoneId string = shouldDeployNetworking ? redisDnsZone.id : ''
output storageBlobDnsZoneName string = shouldDeployNetworking ? storageBlobDnsZone.name : ''
output redisDnsZoneName string = shouldDeployNetworking ? redisDnsZone.name : ''
