/*
  Defines an Azure Key Vault resource for WinGit application
  - Secrets are created for each item in the 'secrets' object
  - Uses RBAC authorization for secure access
  - Other resources will handle their own role assignments to this Key Vault
*/

targetScope = 'resourceGroup'

import * as naming from '../../shared/naming.bicep'

param config object

@secure()
param secrets object = {}

var secretItems = items(secrets)

/*
Defines an Azure Key Vault resource for use by WinGit
  - Secrets are created for each item in the 'secretItems' array
  - Uses RBAC authorization for secure access
*/
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: naming.getKeyVaultName(config.solutionName, 'secrets', resourceGroup().id)
  location: config.location
  properties: {
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
    createMode: 'default'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    accessPolicies: []
  }
}

/*
Creates secrets in the Key Vault for each item in the secrets object
*/
resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [for item in secretItems : if (item.value != null && item.value != '') {
  name: item.key
  parent: keyVault
  properties: {
    value: item.value
  }
}]

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
