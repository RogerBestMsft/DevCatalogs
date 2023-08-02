@description('The name of the Azure Container Registry')
param AcrName string = 'aksregistryrbestpublic'

@description('The location of the ACR and where to deploy the module resources to')
param location string = 'eastus'

@description('How the deployment script should be forced to execute')
param forceUpdateTag  string = utcNow()

@description('Azure RoleId that are required for the DeploymentScript resource to import images')
param rbacRoleNeeded string = 'b24988ac-6180-42a0-ab88-20f7382dd24c' //Contributor is needed to build ACR tasks

@description('Does the Managed Identity already exists, or should be created')
param useExistingManagedIdentity bool = false

@description('Name of the Managed Identity resource')
param managedIdentityName string = 'id-ACRNameAlpha'

@description('A delay before the script import operation starts. Primarily to allow Azure AAD Role Assignments to propagate')
param initialScriptDelay string = '30s'

@allowed([
  'OnSuccess'
  'OnExpiration'
  'Always'
])
@description('When the script resource is cleaned up')
param cleanupPreference string = 'OnSuccess'

resource acr 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: AcrName
}

resource newDepScriptId 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = if (!useExistingManagedIdentity) {
  name: managedIdentityName
  location: location
}

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(rbacRoleNeeded)) {
  name: guid(acr.id, rbacRoleNeeded, newDepScriptId.id)
  scope: acr
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', rbacRoleNeeded)
    principalId: newDepScriptId.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource createNameAndDeploy 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'ACR-Build-Alpha'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${newDepScriptId.id}': {}
    }
  }
  kind: 'AzureCLI'
  dependsOn: [
    rbac
  ]
  properties: {
    forceUpdateTag: forceUpdateTag
    azCliVersion: '2.30.0'
    timeout: 'PT45M'
    retentionInterval: 'P1D'
    environmentVariables: [      
      {
        name: 'initialDelay'
        value: initialScriptDelay
      }
    ]
    scriptContent: loadTextContent('azAcrBuild.sh')
    cleanupPreference: cleanupPreference
  }
}
