/*
  Defines an Azure Storage Account for Azure Functions internal operations
  - Used only for Functions App file share, logs, and internal operations  
  - Always public but secured with Azure AD for Functions platform access
  - Separate from application data storage for security isolation
  - Simple configuration to ensure Functions App can be created successfully
*/

targetScope = 'resourceGroup'

import * as naming from '../../shared/naming.bicep'

param config object
param keyVaultName string

/*
  Creates the Functions storage account with simple public configuration
  This storage is only used by Azure Functions platform, not for application data
*/
resource functionsStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${naming.getStorageAccountName(config.solutionName)}func'  // Add 'func' suffix
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
    publicNetworkAccess: 'Enabled'      // Always enabled for Functions platform access
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      bypass: 'AzureServices'           // Allow Azure services (Functions platform)
      defaultAction: 'Allow'            // Allow public access for Functions operations
    }
  }
}

/*
  Reference existing Key Vault
*/
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

/*
  Store Functions storage connection string in Key Vault
  Always uses public endpoints since this is for Functions platform access
*/
resource functionsStorageConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'functions-storage-connection-string'
  parent: keyVault
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${functionsStorageAccount.name};AccountKey=${functionsStorageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  }
}

output functionsStorageAccountId string = functionsStorageAccount.id
output functionsStorageAccountName string = functionsStorageAccount.name
