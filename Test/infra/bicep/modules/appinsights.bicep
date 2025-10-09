/*
  Defines an Azure Application Insights resource for WinGit application monitoring
  - Stores instrumentation key in Key Vault for use by Functions App
  - Configured for web application monitoring
  - References existing Log Analytics Workspace
*/

targetScope = 'resourceGroup'

import * as naming from '../../shared/naming.bicep'

param config object
param keyVaultName string
param logAnalyticsWorkspaceName string

/*
Reference to existing Log Analytics Workspace
*/
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

/*
Defines an Azure Application Insights resource for monitoring
*/
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: naming.getAppInsightsName(config.solutionName)
  location: config.location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

/*
Reference to existing Key Vault for storing secrets
*/
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

/*
Store Application Insights instrumentation key in Key Vault
*/
resource instrumentationKeySecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'AppInsights-InstrumentationKey'
  parent: keyVault
  properties: {
    value: appInsights.properties.InstrumentationKey
  }
}

/*
Store Application Insights connection string in Key Vault
*/
resource connectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'AppInsights-ConnectionString'
  parent: keyVault
  properties: {
    value: appInsights.properties.ConnectionString
  }
}

output appInsightsId string = appInsights.id
output appInsightsName string = appInsights.name
output instrumentationKey string = appInsights.properties.InstrumentationKey
output connectionString string = appInsights.properties.ConnectionString
