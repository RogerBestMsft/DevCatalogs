/*
  This file serves as the entry point for the WinGit infrastructure deployment.
  It defines the main resources and configurations required to set up the application.
*/

targetScope = 'subscription'

import * as naming from '../shared/naming.bicep'

param config object

@secure()
param secrets object

/*
  Defines a resource group in Azure using the Microsoft.Resources/resourceGroups resource type.
*/
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: naming.getResourceGroupName(config.solutionName)
  location: config.location
}

/*
  Module deployment for the Key Vault resource.
*/
module keyVault './modules/keyvault.bicep' = {
  name: '${take(deployment().name, 36)}-kv'
  scope: rg
  params: {
    config: config
    secrets: secrets
  }
}

/*
  Module deployment for Networking infrastructure (VNet, subnets, NSGs)
*/
module networking './modules/networking.bicep' = {
  name: '${take(deployment().name, 36)}-net'
  scope: rg
  params: {
    config: config
  }
}

/*
  Module deployment for Private DNS Zones
*/
module dns './modules/dns.bicep' = {
  name: '${take(deployment().name, 36)}-dns'
  scope: rg
  params: {
    config: config
    vnetId: networking.outputs.vnetId
    shouldDeployNetworking: networking.outputs.shouldDeployNetworking
  }
}

/*
  Module deployment for the Functions Storage Account (platform operations only)
*/
module functionsStorage './modules/storage.bicep' = {
  name: '${take(deployment().name, 36)}-func-st'
  scope: rg
  params: {
    config: config
    keyVaultName: keyVault.outputs.keyVaultName
  }
}

/*
  Module deployment for the Application Storage Account (private data storage)
*/
module appStorage './modules/app-storage.bicep' = {
  name: '${take(deployment().name, 36)}-app-st'
  scope: rg
  params: {
    config: config
    keyVaultName: keyVault.outputs.keyVaultName
    enablePrivateAccessOnly: networking.outputs.enablePrivateAccessOnly
    enablePrivateEndpoints: networking.outputs.enablePrivateEndpoints
    enableFunctionsVNetIntegration: networking.outputs.enableFunctionsVNetIntegration
    privateEndpointHostname: networking.outputs.shouldDeployNetworking ? '${naming.getStorageAccountName(config.solutionName)}app.privatelink.blob.${environment().suffixes.storage}' : ''
  }
}

/*
  Module deployment for the Log Analytics Workspace resource.
*/
module logAnalytics './modules/loganalytics.bicep' = {
  name: '${take(deployment().name, 36)}-law'
  scope: rg
  params: {
    config: config
  }
}

/*
  Module deployment for the Application Insights resource.
*/
module appInsights './modules/appinsights.bicep' = {
  name: '${take(deployment().name, 36)}-ai'
  scope: rg
  params: {
    config: config
    keyVaultName: keyVault.outputs.keyVaultName
    logAnalyticsWorkspaceName: logAnalytics.outputs.workspaceName
  }
}

/*
  Module deployment for the Redis Cache resource.
*/
module redisCache './modules/redis.bicep' = {
  name: '${take(deployment().name, 36)}-redis'
  scope: rg
  params: {
    config: config
    keyVaultName: keyVault.outputs.keyVaultName
    enablePrivateAccessOnly: networking.outputs.enablePrivateAccessOnly
    enablePrivateEndpoints: networking.outputs.enablePrivateEndpoints
    enableFunctionsVNetIntegration: networking.outputs.enableFunctionsVNetIntegration
    privateEndpointHostname: networking.outputs.shouldDeployNetworking ? '${naming.getRedisCacheName(config.solutionName)}.privatelink.redis.cache.windows.net' : ''
  }
}

/*
  Module deployment for Private Endpoints (after app storage and Redis are created)
*/
module privateEndpoints './modules/private-endpoints.bicep' = {
  name: '${take(deployment().name, 36)}-pe'
  scope: rg
  params: {
    config: config
    storageAccountId: appStorage.outputs.appStorageAccountId
    redisId: redisCache.outputs.redisCacheId
    privateEndpointsSubnetId: networking.outputs.privateEndpointsSubnetId
    storageBlobDnsZoneId: dns.outputs.storageBlobDnsZoneId
    redisDnsZoneId: dns.outputs.redisDnsZoneId
    shouldDeployNetworking: networking.outputs.shouldDeployNetworking
  }

}

/*
  Module deployment for the Azure Functions App resource.
*/
module functions './modules/functions.bicep' = {
  name: '${take(deployment().name, 36)}-func'
  scope: rg
  params: {
    config: config
    keyVaultName: keyVault.outputs.keyVaultName
    storageAccountName: functionsStorage.outputs.functionsStorageAccountName
    redisCacheName: redisCache.outputs.redisCacheName
    enableVNetIntegration: networking.outputs.enableFunctionsVNetIntegration
    functionsSubnetId: networking.outputs.functionsSubnetId
    restrictToVNetOnly: networking.outputs.enableFunctionsPrivateAccessOnly
  }
}

/*
  Output the resource group name and Key Vault information for reference
*/
output resourceGroupName string = rg.name
output location string = rg.location
output keyVaultId string = keyVault.outputs.keyVaultId
output keyVaultName string = keyVault.outputs.keyVaultName
output functionsStorageAccountId string = functionsStorage.outputs.functionsStorageAccountId
output functionsStorageAccountName string = functionsStorage.outputs.functionsStorageAccountName
output appStorageAccountId string = appStorage.outputs.appStorageAccountId
output appStorageAccountName string = appStorage.outputs.appStorageAccountName
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId
output logAnalyticsWorkspaceName string = logAnalytics.outputs.workspaceName
output appInsightsId string = appInsights.outputs.appInsightsId
output appInsightsName string = appInsights.outputs.appInsightsName
output functionAppId string = functions.outputs.functionAppId
output functionAppName string = functions.outputs.functionAppName
output functionAppUrl string = functions.outputs.functionAppUrl
output appServicePlanId string = functions.outputs.appServicePlanId
output appServicePlanName string = functions.outputs.appServicePlanName
output redisCacheId string = redisCache.outputs.redisCacheId
output redisCacheName string = redisCache.outputs.redisCacheName
output redisHostName string = redisCache.outputs.redisHostName
output vnetId string = networking.outputs.vnetId
output vnetName string = networking.outputs.vnetName
output enablePrivateEndpoints bool = networking.outputs.enablePrivateEndpoints
output enablePrivateAccessOnly bool = networking.outputs.enablePrivateAccessOnly
output enableFunctionsVNetIntegration bool = networking.outputs.enableFunctionsVNetIntegration
