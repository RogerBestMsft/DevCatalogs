param projectName  string
param envTypeObject object = {}

// Contributor
//param creatorRoleAssignment string = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

@sys.description('Tags to apply to the resources')
param tags object = {}

var creatorRole = string(envTypeObject.CreatorRoles)

resource project 'Microsoft.DevCenter/projects@2023-01-01-preview' existing = {
  name: projectName
}

resource environmentType 'Microsoft.DevCenter/projects/environmentTypes@2023-01-01-preview' = {
  name: envTypeObject.name
  parent: project
  location: envTypeObject.location
  identity: {
    type: envTypeObject.identity.idtype
  }
  properties: {
    status: 'Enabled'
    #disable-next-line use-resource-id-functions
    deploymentTargetId: '/subscriptions/${envTypeObject.subscriptionId}'
    creatorRoleAssignment: {
      roles: {
        '${creatorRole}': {}
      }
    }
  }
  tags: tags
}

// resource environmentTypeAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid('ade', devCenterId, projectName, name, ciPrincipalId)
//   properties: {
//     // DevCenter Environments User
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18e40d4e-8d2e-438d-97e1-9528336e149c')
//     principalId: ciPrincipalId
//     principalType: 'ServicePrincipal'
//   }
//   scope: environmentType
// }

output xxx string = creatorRole
