param prefix string

param location string  = resourceGroup().location
param utcValue string = utcNow()

var storageAccountName = '${prefix}storage'
var storageAccountBName = '${prefix}storageb'
param vnetName string = '${prefix}Vnet'
var subnetName = '${prefix}Subnet'
var privatesubnetName = '${prefix}privateSubnet'
var userAssignedIdentityName = '${prefix}Identity'
var containerGroupName = '${prefix}Aci'
var dsName = '${prefix}DS'

var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
var privatesubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, privatesubnetName)

@description('Create the VNet')
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    enableDdosProtection: false
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                'westus2'
                'westus'
                'eastus2euap'
                'centraluseuap'
              ]
            }
          ]
          delegations: [
            {
              name: 'Microsoft.ContainerInstance.containerGroups'
              id: '${subnetId}/delegations/Microsoft.ContainerInstance.containerGroups'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: privatesubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                'westus2'
                'westus'
                'eastus2euap'
                'centraluseuap'
              ]
            }
          ]
          delegations: [
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

@description('Create the storage where the deployment script info is stored')
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: subnetId
          action: 'Allow'
          state: 'Succeeded'
        }
      ]
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
  dependsOn: [
    vnet
  ]
}


@description('Create the storage with necessary settings to test the deployment script')
resource storageAccountb 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountBName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Disabled'
    allowCrossTenantReplication: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: privatesubnetId
          action: 'Allow'
          state: 'Succeeded'
        }
      ]
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
  dependsOn: [
    vnet
  ]
}


resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  name: 'default'
  parent: storageAccountb
}

// Create containers if specified
resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  parent: blobService
  name: 'testconfig'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: 'PrivateEndpoint1'
  location: location
  properties: {
    subnet: {
      id: privatesubnetId
    }
    privateLinkServiceConnections: [
      {
        properties: {
          privateLinkServiceId: storageAccountb.id
          groupIds: [
            'blob'
          ]
        }
        name: 'PrivateEndpoint1'
      }
    ]
  }
}

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  properties: {}
}
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZones.name}/${privateDnsZones.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${privateEndpoint.name}/dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZones.id
        }
      }
    ]
  }
}

@description('Create the user managed identity')
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: userAssignedIdentityName
  location: location
}

@description('get the built-in role definition Storage File Data Privileged Contributor')
resource storageFileDataPrivilegedContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '69566ab7-960f-475b-8e7c-b3118f30c6bd'
  scope: tenant()
}

@description('get the built-in role definition Contributor')
resource contributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  scope: tenant()
}


@description('assign the built in role to the storage account')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageFileDataPrivilegedContributor.id, userAssignedIdentity.id, storageAccount.id)
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    roleDefinitionId: storageFileDataPrivilegedContributor.id
    principalType: 'ServicePrincipal'
  }
  scope: storageAccount
}

@description('assign the built in role to the storage account')
resource roleAssignmentb 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageFileDataPrivilegedContributor.id, userAssignedIdentity.id, storageAccountb.id)
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    roleDefinitionId: storageFileDataPrivilegedContributor.id
    principalType: 'ServicePrincipal'
  }
  scope: storageAccountb
}

@description('assign the necessary role for the deployment script.')
resource roleAssignmentc 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(contributor.id, userAssignedIdentity.id, storageAccountb.id)
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    roleDefinitionId: contributor.id
    principalType: 'ServicePrincipal'
  }
  scope: resourceGroup()
}

@description('deployment script to push a file to the target storage b')
resource dsTest 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: dsName
  location: location
  identity: {
    type: 'userAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  kind: 'AzurePowerShell'
  properties: {
    forceUpdateTag: utcValue
    azPowerShellVersion: '9.7'
    storageAccountSettings: {
      storageAccountName: storageAccountName
    }
    containerSettings: {
      containerGroupName: containerGroupName
      subnetIds: [
        {
          id: '${vnet.id}/subnets/${subnetName}'
        }
      ]
    }
    environmentVariables: [
      {
        name: 'resourceGroupName'
        value: resourceGroup().name
      }
      {
        name: 'storageAccountName'
        value: storageAccountb.name
      }
    ]
    scriptContent: '''
      Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/Azure/azure-docs-json-samples/master/mslearn-arm-deploymentscripts-sample/appsettings.json' -OutFile 'appsettings.json'
      $storageAccount = Get-AzStorageAccount -ResourceGroupName ${Env:resourceGroupName} | Where-Object { $_.StorageAccountName -like ${Env:storageAccountName} }
      $blob = Set-AzStorageBlobContent -File 'appsettings.json' -Container 'testconfig' -Blob 'appsettings.json' -Context $storageAccount.Context
      $DeploymentScriptOutputs = @{}
      $DeploymentScriptOutputs['storageAccount'] = $storageAccount
      $DeploymentScriptOutputs['Test'] = 'Bravo'
    '''
    retentionInterval: 'P1D'
    cleanupPreference: 'OnExpiration'
  }
  dependsOn: [
    roleAssignment
    roleAssignmentb
    roleAssignmentc
  ]
}
