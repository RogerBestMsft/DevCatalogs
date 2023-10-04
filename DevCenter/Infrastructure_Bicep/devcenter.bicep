
targetScope = 'resourceGroup'

@description('DevCenter input')
param devCenterInput object = {}


@description('Tags to apply to the resources')
param tags object = {}

var randomString = 'abcdefgh'

// docs: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-secrets-officer
var secretsAssignmentId = guid('${randomString}${resourceGroup().id}${devCenterInput.keyVaultName}${devCenterInput.name}')
var secretsOfficerRoleResourceId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')

var galleryAssignmentId = guid('${randomString}${resourceGroup().id}${devCenterInput.galleryName}${devCenterInput.name}')
var galleryContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')


resource devCenter 'Microsoft.DevCenter/devcenters@2023-01-01-preview' = {
  name: devCenterInput.name
  location: devCenterInput.location
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
}

// assign dev center identity owner role on subscription
module subscriptionAssignment 'subscriptionRoles.bicep' = {
  name: '${devCenterInput.name}-SubscriptionAssignment'
  scope: subscription()
  params: {
    principalId: devCenter.identity.principalId
    role: 'Owner'
    principalType: 'ServicePrincipal'
  }
}

// assign dev center identity owner role on each environment type subscription
module envSubscriptionsAssignment 'subscriptionRoles.bicep' = [for envType in devCenterInput.environmentTypes: {
  name: guid('owner${devCenterInput.name}${envType}')
  scope: subscription()
  params: {
    principalId: devCenter.identity.principalId
    role: 'Owner'
    principalType: 'ServicePrincipal'
  }
}]

// create the catalog
resource catalog 'Microsoft.DevCenter/devcenters/catalogs@2023-01-01-preview' = {
  parent: devCenter
  name: 'Environments'
  properties: {
    gitHub: {
      uri: devCenterInput.repoUri
      branch: 'main'
      path: devCenterInput.repoPath
      secretIdentifier: repoAccessSecret.properties.secretUri
    }
  }
}

// create the dev center level environment types
resource envTypes 'Microsoft.DevCenter/devcenters/environmentTypes@2023-01-01-preview' = [for envType in devCenterInput.environmentTypes: {
  parent: devCenter
  name: envType
  properties: {}
}]

// ------------------
// Key Vault
// ------------------

// create a key vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: devCenterInput.keyVaultName
  location: devCenterInput.location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    sku: {
      family: 'A'
      name: 'standard'
    }
  }
  tags: tags
}

// assign dev center identity secrets officer role on key vault
resource keyVaultAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: secretsAssignmentId
  properties: {
    principalId: devCenter.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: secretsOfficerRoleResourceId
  }
  scope: keyVault
}

// add the github pat token to the key vault
resource repoAccessSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'github-pat'
  parent: keyVault
  properties: {
    value: devCenterInput.repoAccess
    attributes: {
      enabled: true
    }
  }
  tags: tags
}

// ------------------
// Compute Gallery
// ------------------

// create a compute gallery
resource gallery 'Microsoft.Compute/galleries@2022-03-03' = {
  name: devCenterInput.galleryName
  location: devCenterInput.location
  properties: {
    description: 'Custom gallery'
  }
}

resource galleryAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: gallery
  name: galleryAssignmentId
  properties: {
    roleDefinitionId: galleryContributor
    principalType: 'ServicePrincipal'
    principalId: devCenter.identity.principalId
  }
}

resource dcgallery 'Microsoft.DevCenter/devcenters/galleries@2023-04-01' = {
  name: devCenterInput.name
  parent: devCenter
  properties: {
    galleryResourceId: gallery.id
  }
  dependsOn: [
    galleryAssignment
  ]
}

// Add devbox definition
module devBoxDefinitionCreation 'devboxDefinition.bicep' = [for dbDef in devCenterInput.devboxDefinitions: {
  dependsOn: [
    devCenter
  ]
  name: '${dbDef.name}-DBDCreate'
  params: {
   location: devCenterInput.location
   dbDefName: dbDef.name
   devCenterName: devCenterInput.name
   galleryName: dbDef.galleryName
   imageName: dbDef.imageName
   imageVersion: dbDef.imageVersion
   storage: dbDef.storage
   compute: dbDef.compute
   tags: tags
  }
}]

// ------------------
// Organization Networking
// ------------------

resource organizationvnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: devCenterInput.vnet.name
  location: devCenterInput.location
  properties: {
    addressSpace: {
      addressPrefixes: devCenterInput.vnet.ipRanges
    }
    subnets: [for subnet in devCenterInput.vnet.subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.ipRange
        }
      }
    ]
  }
  tags: tags
}

output devCenterId string = devCenter.id
output devCenterName string = devCenter.name
output devCenterIdentity string = devCenter.identity.principalId
