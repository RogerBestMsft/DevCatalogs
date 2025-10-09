/*
  Defines an Azure Storage Account for WinGit application data (packages, manifests)
  - Separate from Functions storage for security isolation
  - Fully private with endpoints and access restrictions
  - Creates blob containers for application data
  - Only accessible via private endpoints when enabled
*/

targetScope = 'resourceGroup'

import * as naming from '../../shared/naming.bicep'

param config object
param keyVaultName string

@description('Whether to restrict access to private endpoints only')
param enablePrivateAccessOnly bool = false
// ↳ When true: Blocks all public internet access, only allows VNet traffic
// ↳ When false: Allows public internet access (can be combined with IP restrictions)

@description('Whether private endpoints are enabled (affects connection string generation)')
param enablePrivateEndpoints bool = false
// ↳ When true: Uses private endpoint hostname in connection strings
// ↳ When false: Uses standard public hostname in connection strings

@description('Whether Functions App is VNet integrated (affects connection string)')
param enableFunctionsVNetIntegration bool = false
// ↳ When true: Functions App can use private endpoints
// ↳ When false: Functions App needs public endpoints even with private access restrictions

@description('Private endpoint hostname for storage (when private endpoints enabled)')
param privateEndpointHostname string = ''

// Network Access Control Lists for application data storage
var networkAcls = enablePrivateAccessOnly ? {
  bypass: 'None'                   // No bypass for application data - strict private access
  defaultAction: 'Deny'            // Deny all public access
  virtualNetworkRules: []          // VNet rules managed through private endpoints
} : {
  bypass: 'AzureServices'          // Allow Azure services when public access enabled
  defaultAction: 'Allow'           // Allow public access
}

/*
  Creates the application data storage account with strict networking configuration
*/
resource appStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${naming.getStorageAccountName(config.solutionName)}app'  // Add 'app' suffix
  location: config.location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: true
    publicNetworkAccess: enablePrivateAccessOnly ? 'Disabled' : 'Enabled'
    networkAcls: networkAcls
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

/*
  Get the blob service for container creation
*/
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: appStorageAccount
}

/*
  Create blob containers for application data
*/
resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = [for containerName in ['packages', 'manifests', 'logs']: {
  name: containerName
  parent: blobServices
  properties: {
    publicAccess: 'None'
  }
}]

/*
  Reference existing Key Vault
*/
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

/*
  Store application storage connection string in Key Vault
  Uses private endpoint hostname only when Functions App is VNet integrated
*/
resource appStorageConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'app-storage-connection-string'
  parent: keyVault
  properties: {
    value: enablePrivateEndpoints && enableFunctionsVNetIntegration && !empty(privateEndpointHostname) 
      ? 'DefaultEndpointsProtocol=https;AccountName=${appStorageAccount.name};AccountKey=${appStorageAccount.listKeys().keys[0].value};BlobEndpoint=https://${privateEndpointHostname}/'
      : 'DefaultEndpointsProtocol=https;AccountName=${appStorageAccount.name};AccountKey=${appStorageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  }
}

/*
  Store application storage account name as a separate secret
*/
resource appStorageAccountNameSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'app-storage-account-name'
  parent: keyVault
  properties: {
    value: appStorageAccount.name
  }
}

output appStorageAccountId string = appStorageAccount.id
output appStorageAccountName string = appStorageAccount.name
