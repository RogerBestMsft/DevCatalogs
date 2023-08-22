targetScope = 'resourceGroup'

param projectObject object = {}

param devCenterObject object = {}

@sys.description('Tags to apply to the resources')
param tags object = {}

//var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource project 'Microsoft.DevCenter/projects@2023-01-01-preview' = {
  name: projectObject.name
  location: projectObject.location
  properties: {    
    devCenterId: devCenterObject.devCenter.Id
  }
  tags: tags
}

// assign dev center identity owner role on each environment type subscription
module networkCreation 'network.bicep' = [for vnet in projectObject.vnet: {
  name: '${vnet.name}-Create' //guid('owner${projectObject.name}')
  scope: resourceGroup()  
  params: {
    devCenterId: devCenterObject.devCenter.Id
    vnetObject: vnet
    tags: tags
  }
}]

// Add users admin - Devbox User - ADE User
module roleCreation 'projectRoles.bicep' = [for (projectAdmin,i) in projectObject.ProjectAdmins: {
  name: '${projectObject.name}${i}-AdminCreate'
  params: {
    principalId: projectAdmin
    projectName: projectObject.name
    roles: [
      'ProjectAdmin'
    ]
    principalType: 'User'    
  }
}]


// Add environments
// module envTypeCreation 'projectEnvironmentType.bicep' = [for envType in projectObject.environmentTypes: {
//   name: '${envType.name}-EnvCreate'
//   params: {
//     projectName: projectObject.name
//     envTypeObject: envType
//     tags: tags
//   }
// }]



// Add pools

//
