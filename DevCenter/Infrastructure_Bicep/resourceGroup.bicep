targetScope = 'subscription'

param resourceObject object = {}
@description('Tags to apply to the resources')
param tags object = {}

resource RGroupCreate 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceObject.resourceGroupName
  location: resourceObject.location
  tags: tags
}
