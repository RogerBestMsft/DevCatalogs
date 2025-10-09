/*
  Defines an Azure Log Analytics Workspace for centralized logging and monitoring
  - Used by Application Insights and other Azure services
  - Configured with appropriate retention and pricing tier
*/

targetScope = 'resourceGroup'

import * as naming from '../../shared/naming.bicep'

param config object

/*
Log Analytics Workspace for centralized logging
*/
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: naming.getLogAnalyticsWorkspaceName(config.solutionName)
  location: config.location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

output workspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name
