/*
  Defines networking infrastructure for the WinGit application
  - Creates Virtual Network with configurable address space
  - Adds subnets for Functions App VNet integration and private endpoints
  - Configures Network Security Groups for each subnet
  - Only deploys when private networking is enabled
*/

targetScope = 'resourceGroup'

import * as naming from '../../shared/naming.bicep'

@description('Configuration object containing solution settings')
param config object

// Networking configuration with enterprise-grade security defaults
var networkingConfig = config.?networking ?? {}

// Enterprise-grade security defaults (can be overridden per environment)
var enablePrivateEndpoints = networkingConfig.?enablePrivateEndpoints ?? true
// ↳ Creates private endpoints for Storage Account and Redis Cache
//   When enabled: Resources only accessible from within VNet
//   When disabled: Resources accessible from public internet

var enablePrivateAccessOnly = networkingConfig.?enablePrivateAccessOnly ?? true
// ↳ Blocks all public internet access to Storage Account and Redis Cache
//   When enabled: Only VNet traffic allowed (requires private endpoints)
//   When disabled: Public internet access permitted (can use IP restrictions)

var enableFunctionsVNetIntegration = networkingConfig.?enableFunctionsVNetIntegration ?? true
// ↳ Connects Functions App to VNet for outbound traffic to private endpoints
//   When enabled: Functions can reach private endpoints via VNet integration  
//   When disabled: Functions uses public internet for outbound connections

var enableFunctionsPrivateAccessOnly = networkingConfig.?enableFunctionsPrivateAccessOnly ?? enableFunctionsVNetIntegration
// ↳ Restricts Functions App inbound access to VNet only
//   When enabled: Functions only accessible from VNet (via VPN/Bastion)
//   When disabled: Functions accessible from public internet

// VNet configuration with defaults
var vnetConfig = networkingConfig.?vnet ?? {
  addressSpace: '10.0.0.0/16'
  subnets: {
    functions: '10.0.1.0/24'
    privateEndpoints: '10.0.2.0/24'
  }
}

// Deploy networking resources when private endpoints are enabled
var shouldDeployNetworking = enablePrivateEndpoints

/*
  Virtual Network for private networking
*/
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = if (shouldDeployNetworking) {
  name: naming.getVirtualNetworkName(config.solutionName)
  location: config.location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetConfig.addressSpace]
    }
    subnets: [
      {
        name: 'snet-functions'
        properties: {
          addressPrefix: vnetConfig.subnets.functions
          delegations: [
            {
              name: 'delegation-functions'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          networkSecurityGroup: {
            id: functionsNsg.id
          }
        }
      }
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: vnetConfig.subnets.privateEndpoints
          networkSecurityGroup: {
            id: privateEndpointsNsg.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

/*
  Network Security Group for Functions subnet
*/
resource functionsNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = if (shouldDeployNetworking) {
  name: naming.getNetworkSecurityGroupName(config.solutionName, 'functions')
  location: config.location
  properties: {
    securityRules: [
      {
        name: 'AllowFunctionsOutbound'
        properties: {
          description: 'Allow Functions App outbound traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['80', '443']
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowAzureServicesOutbound'
        properties: {
          description: 'Allow access to Azure services'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
    ]
  }
}

/*
  Network Security Group for Private Endpoints subnet
*/
resource privateEndpointsNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = if (shouldDeployNetworking) {
  name: naming.getNetworkSecurityGroupName(config.solutionName, 'private-endpoints')
  location: config.location
  properties: {
    securityRules: [
      {
        name: 'AllowVNetInbound'
        properties: {
          description: 'Allow inbound traffic from VNet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['443', '6380'] // HTTPS and Redis SSL
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          description: 'Deny all other inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
    ]
  }
}

/*
  Outputs for use by other modules
*/
output vnetId string = shouldDeployNetworking ? virtualNetwork.id : ''
output vnetName string = shouldDeployNetworking ? virtualNetwork.name : ''
output functionsSubnetId string = shouldDeployNetworking ? '${virtualNetwork.id}/subnets/snet-functions' : ''
output privateEndpointsSubnetId string = shouldDeployNetworking ? '${virtualNetwork.id}/subnets/snet-private-endpoints' : ''
output functionsSubnetName string = shouldDeployNetworking ? 'snet-functions' : ''
output privateEndpointsSubnetName string = shouldDeployNetworking ? 'snet-private-endpoints' : ''
output shouldDeployNetworking bool = shouldDeployNetworking
output enablePrivateEndpoints bool = enablePrivateEndpoints
output enablePrivateAccessOnly bool = enablePrivateAccessOnly
output enableFunctionsVNetIntegration bool = enableFunctionsVNetIntegration
output enableFunctionsPrivateAccessOnly bool = enableFunctionsPrivateAccessOnly
