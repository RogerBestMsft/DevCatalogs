/*
  Defines Private Endpoints for the WinGit application
  - Creates private endpoints for Storage Account and Redis Cache
  - Configures DNS zone groups for automatic DNS registration
  - Only deploys when private endpoints are enabled
*/

targetScope = 'resourceGroup'

import * as naming from '../../shared/naming.bicep'

@description('Configuration object containing solution settings')
param config object

@description('Storage Account resource ID')
param storageAccountId string

@description('Redis Cache resource ID')
param redisId string

@description('Private endpoints subnet ID')
param privateEndpointsSubnetId string

@description('Storage blob DNS zone ID')
param storageBlobDnsZoneId string

@description('Redis DNS zone ID')
param redisDnsZoneId string

@description('Whether networking resources should be deployed')
param shouldDeployNetworking bool

/*
  Private Endpoint for Storage Account (Blob service)
*/
resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (shouldDeployNetworking) {
  name: naming.getPrivateEndpointName(config.solutionName, 'storage')
  location: config.location
  properties: {
    subnet: {
      id: privateEndpointsSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-connection'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: ['blob']
        }
      }
    ]
  }
}

/*
  DNS Zone Group for Storage Private Endpoint
*/
resource storagePrivateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = if (shouldDeployNetworking) {
  name: 'default'
  parent: storagePrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: storageBlobDnsZoneId
        }
      }
    ]
  }
}

/*
  Private Endpoint for Redis Cache
*/
resource redisPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (shouldDeployNetworking) {
  name: naming.getPrivateEndpointName(config.solutionName, 'redis')
  location: config.location
  properties: {
    subnet: {
      id: privateEndpointsSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'redis-connection'
        properties: {
          privateLinkServiceId: redisId
          groupIds: ['redisCache']
        }
      }
    ]
  }
}

/*
  DNS Zone Group for Redis Private Endpoint
*/
resource redisPrivateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = if (shouldDeployNetworking) {
  name: 'default'
  parent: redisPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: redisDnsZoneId
        }
      }
    ]
  }
}

/*
  Outputs for reference
*/
output storagePrivateEndpointId string = shouldDeployNetworking ? storagePrivateEndpoint.id : ''
output redisPrivateEndpointId string = shouldDeployNetworking ? redisPrivateEndpoint.id : ''
output storagePrivateEndpointName string = shouldDeployNetworking ? storagePrivateEndpoint.name : ''
output redisPrivateEndpointName string = shouldDeployNetworking ? redisPrivateEndpoint.name : ''
