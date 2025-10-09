/*
  Defines an Azure Functions App for the WinGit REST API service
  - Creates App Service Plan with Consumption tier for cost optimization
  - Configures Function App with .NET 8 Isolated runtime
  - Integrates with Key Vault for configuration secrets
  - Connects to Application Insights for monitoring
  - References existing Storage Account for function storage
*/

targetScope = 'resourceGroup'

import * as naming from '../../shared/naming.bicep'

@description('Configuration object containing solution settings')
param config object

@description('Name of the existing Key Vault for storing secrets')
param keyVaultName string

@description('Name of the existing Storage Account for blob storage')
param storageAccountName string

@description('Name of the existing Redis Cache for caching')
param redisCacheName string

@description('Whether VNet integration should be enabled for Functions App')
param enableVNetIntegration bool = false
// ↳ When true: Connects Functions App to VNet for outbound traffic to private endpoints
// ↳ When false: Functions App uses public internet for outbound connections

@description('Subnet ID for Functions App VNet integration')
param functionsSubnetId string = ''

@description('Whether to restrict Functions App access to VNet only')
param restrictToVNetOnly bool = false
// ↳ When true: Blocks all public internet access to Functions App (requires VPN/Bastion)
// ↳ When false: Functions App accessible from public internet

/*
  Reference to existing Key Vault
*/
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

/*
  Reference to existing Storage Account
*/
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

/*
  Reference to existing Redis Cache
*/
resource redisCache 'Microsoft.Cache/redis@2023-08-01' existing = {
  name: redisCacheName
}

/*
  Creates the App Service Plan for the Function App
  Uses Premium when VNet integration is enabled, Consumption otherwise
*/
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: naming.getAppServicePlanName(config.solutionName)
  location: config.location
  sku: enableVNetIntegration ? {
    name: 'EP1'        // Premium Elastic Plan for VNet integration
    tier: 'ElasticPremium'
    size: 'EP1'
    family: 'EP'
    capacity: 1
  } : {
    name: 'Y1'         // Consumption plan for basic usage
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
}

/*
  Creates the Azure Functions App with .NET 8 Isolated runtime
  Initial deployment without Key Vault references to avoid permission issues
*/
resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: naming.getFunctionAppName(config.solutionName)
  location: config.location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      netFrameworkVersion: 'v8.0'
      use32BitWorkerProcess: false
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(naming.getFunctionAppName(config.solutionName))
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'STORAGE_ACCOUNT_NAME'
          value: storageAccountName
        }
      ]
    }
  }
}

/*
  Configure VNet integration for Functions App (when enabled)
*/
resource functionAppVNetIntegration 'Microsoft.Web/sites/networkConfig@2023-01-01' = if (enableVNetIntegration && !empty(functionsSubnetId)) {
  name: 'virtualNetwork'
  parent: functionApp
  properties: {
    subnetResourceId: functionsSubnetId
    swiftSupported: true
  }
}

/*
  Configure access restrictions for Functions App (when VNet-only access is enabled)
*/
resource functionAppAccessRestrictions 'Microsoft.Web/sites/config@2023-01-01' = if (restrictToVNetOnly && enableVNetIntegration) {
  name: 'web'
  parent: functionApp
  properties: {
    ipSecurityRestrictions: [
      {
        action: 'Allow'
        description: 'Allow access from VNet'
        name: 'VNet Access'
        priority: 100
        vnetSubnetResourceId: functionsSubnetId
      }
      {
        action: 'Deny'
        description: 'Deny all other access'
        name: 'Deny All'
        priority: 2147483647
        ipAddress: '0.0.0.0/0'
      }
    ]
  }
  dependsOn: [
    functionAppVNetIntegration
  ]
}

/*
  Update Function App configuration with Key Vault references after RBAC is configured
*/
resource functionAppConfig 'Microsoft.Web/sites/config@2023-01-01' = {
  name: 'appsettings'
  parent: functionApp
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=functions-storage-connection-string)'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=functions-storage-connection-string)'
    WEBSITE_CONTENTSHARE: toLower(naming.getFunctionAppName(config.solutionName))
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
    APPLICATIONINSIGHTS_CONNECTION_STRING: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=AppInsights-ConnectionString)'
    WEBSITE_RUN_FROM_PACKAGE: '1'
    STORAGE_ACCOUNT_NAME: storageAccountName
    REDIS_HOSTNAME: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=redis-hostname)'
    REDIS_SSL_PORT: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=redis-ssl-port)'
  }
  dependsOn: [
    roleAssignmentKeyVaultSecretsUser
    roleAssignmentStorageBlobDataContributor
    roleAssignmentRedisCacheContributor
  ]
}

/*
  Assign Key Vault Secrets User role to the Function App's managed identity
*/
resource roleDefinitionKeyVaultSecretsUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User role
}

resource roleAssignmentKeyVaultSecretsUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, functionApp.id, roleDefinitionKeyVaultSecretsUser.id)
  scope: keyVault
  properties: {
    roleDefinitionId: roleDefinitionKeyVaultSecretsUser.id
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

/*
  Assign Storage Blob Data Contributor role to the Function App's managed identity
*/
resource roleDefinitionStorageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor role
}

resource roleAssignmentStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, functionApp.id, roleDefinitionStorageBlobDataContributor.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: roleDefinitionStorageBlobDataContributor.id
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

/*
  Assign Redis Cache Contributor role to the Function App's managed identity
*/
resource roleDefinitionRedisCacheContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3' // Redis Cache Contributor role
}

resource roleAssignmentRedisCacheContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(redisCache.id, functionApp.id, roleDefinitionRedisCacheContributor.id)
  scope: redisCache
  properties: {
    roleDefinitionId: roleDefinitionRedisCacheContributor.id
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output functionAppId string = functionApp.id
output functionAppName string = functionApp.name
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output appServicePlanId string = appServicePlan.id
output appServicePlanName string = appServicePlan.name
output principalId string = functionApp.identity.principalId
