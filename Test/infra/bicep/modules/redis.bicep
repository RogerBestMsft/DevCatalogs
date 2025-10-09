/*
  Defines an Azure Cache for Redis for the WinGit application
  - Creates Redis cache with Basic tier for cost optimization
  - Configures Azure AD authentication for secure access
  - Uses RBAC for Function App managed identity access
  - Stores connection info in Key Vault for Functions App access
*/

targetScope = 'resourceGroup'

import * as naming from '../../shared/naming.bicep'

@description('Configuration object containing solution settings')
param config object

@description('Name of the existing Key Vault for storing secrets')
param keyVaultName string

@description('Whether to restrict access to private endpoints only')
param enablePrivateAccessOnly bool = false
// ↳ When true: Blocks all public internet access to Redis Cache
// ↳ When false: Allows public internet access with Azure AD authentication

@description('Whether private endpoints are enabled (affects connection string generation)')
param enablePrivateEndpoints bool = false
// ↳ When true: Uses private endpoint hostname in connection strings
// ↳ When false: Uses standard public hostname in connection strings

@description('Whether Functions App is VNet integrated (affects connection string)')
param enableFunctionsVNetIntegration bool = false
// ↳ When true: Functions App can use private endpoints
// ↳ When false: Functions App needs public endpoints even with private access restrictions

@description('Private endpoint hostname for Redis (when private endpoints enabled)')
param privateEndpointHostname string = ''

// Redis configuration with enterprise-grade defaults
var redisConfig = config.?redis ?? {}

// Enterprise-grade SKU defaults (Standard with HA)
var redisSku = redisConfig.?sku ?? {
  name: 'Standard'
  family: 'C'
  capacity: 1 // 1 GB cache for production workloads
}

// Enterprise-grade security defaults (respects networking configuration)
var redisSettings = redisConfig.?settings ?? {
  enableNonSslPort: false                                             // Security: SSL-only connections
  minimumTlsVersion: '1.2'                                           // Security: Modern TLS version  
  publicNetworkAccess: enablePrivateAccessOnly ? 'Disabled' : 'Enabled' // Controlled by networking config
  maxMemoryPolicy: 'allkeys-lru'                                    // Performance: Efficient memory management
  enableAzureAD: true                                               // Security: Azure AD authentication
}

/*
  Reference to existing Key Vault
*/
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

/*
  Creates the Azure Cache for Redis instance with configurable settings
*/
resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: naming.getRedisCacheName(config.solutionName)
  location: config.location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: redisSku
    enableNonSslPort: redisSettings.enableNonSslPort
    minimumTlsVersion: redisSettings.minimumTlsVersion
    publicNetworkAccess: redisSettings.publicNetworkAccess
    redisConfiguration: {
      'maxmemory-policy': redisSettings.maxMemoryPolicy
      'aad-enabled': redisSettings.enableAzureAD ? 'true' : 'false'
    }
  }
}

/*
  Store Redis hostname in Key Vault for Azure AD authentication
*/
resource redisHostNameSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'redis-hostname'
  parent: keyVault
  properties: {
    value: redisCache.properties.hostName
  }
}

/*
  Store Redis SSL port in Key Vault
*/
resource redisSslPortSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'redis-ssl-port'
  parent: keyVault
  properties: {
    value: string(redisCache.properties.sslPort)
  }
}

/*
  Store Redis connection string for Azure AD authentication
  Uses private endpoint hostname only when Functions App is VNet integrated
*/
resource redisConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'redis-connection-string'
  parent: keyVault
  properties: {
    value: enablePrivateEndpoints && enableFunctionsVNetIntegration && !empty(privateEndpointHostname)
      ? '${privateEndpointHostname}:${redisCache.properties.sslPort},ssl=True,abortConnect=False'
      : '${redisCache.properties.hostName}:${redisCache.properties.sslPort},ssl=True,abortConnect=False'
  }
}

output redisCacheId string = redisCache.id
output redisCacheName string = redisCache.name
output redisHostName string = redisCache.properties.hostName
output redisSslPort int = redisCache.properties.sslPort
output redisNonSslPort int = redisCache.properties.port
