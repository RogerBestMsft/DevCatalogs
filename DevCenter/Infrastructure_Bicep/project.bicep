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
    devCenterId: devCenterObject.devCenterId.value
  }
  tags: tags
}

// Create vnet for each project and add to devcenter
module networkCreation 'network.bicep' = [for vnet in projectObject.vnet: {
  name: '${vnet.name}-Create' //guid('owner${projectObject.name}')
  scope: resourceGroup()
  params: {
    devCenterId: devCenterObject.devCenterId.value
    vnetObject: vnet
    location: project.location
    tags: tags
  }  
}]

// Add users admin - Devbox User - ADE User
module roleCreation 'projectRoles.bicep' = [for (projectAdmin,i) in projectObject.ProjectAdmins: {
  dependsOn: [
    project
  ]
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
module envTypeCreation 'projectEnvironmentType.bicep' = [for (envType,i) in projectObject.environmentTypes: {
  dependsOn: [
    project
  ]
  name: '${envType.type}${i}-EnvCreate'
  params: {
    projectName: projectObject.name
    location: projectObject.location
    envTypeObject: envType
    tags: tags
  }
}]



// Add pools
module poolCreation 'pool.bicep' = [ for (pool,i) in projectObject.pools :{
  dependsOn: [
    project
  ]
  name: '${pool.name}${i}-PoolCreate'
  params: {
    name: pool.name
    projectName: projectObject.name
    location: projectObject.location
    devBoxDefinitionName: pool.definition
    networkConnectionName: networkCreation[0].outputs.networkconnection
    tags: tags
  }
}]
//
