# Read structure from structure.yml
#$structure = Get-Content -Path .\structure.json | ConvertFrom-Json -Depth 20
#$configuration3 = Get-Content -Path '.\structure copy.txt'

. .\structure.ps1


Connect-AzAccount -Subscription $devCenterInput.subscriptionId

import-module -Name Az

$devCenterRG = New-AzDeployment -Name "TestDeployRG" `
    -Location $devCenterInput.location `
    -Debug `
    -TemplateFile .\resourceGroup.bicep `
    -resourceObject $devCenterInput


$devCenter = New-AzResourceGroupDeployment -Name 'TestDelployDC' `
    -ResourceGroupName $devCenterInput.resourceGroupName `
    -Debug `
    -Force `
    -TemplateFile .\devcenter.bicep `
    -devCenterInput $devCenterInput



foreach ($project in $projects) {

    $projectRG = New-AzDeployment -Name "Deploy$($project.name)AResourceGroup" `
    -Location $project.location `
    -Debug `
    -TemplateFile .\resourceGroup.bicep `
    -resourceObject $project

    $newproject = New-AzResourceGroupDeployment -Name "CDeploy$($project.name)" `
    -ResourceGroupName $project.resourceGroupName `
    -Debug `
    -Force `
    -TemplateFile .\project.bicep `
    -projectObject $project `
    -devCenterObject $devCenter.Outputs
    


}   


#Test
New-AzResourceGroupDeployment -Name "TestDeployAlpha" `
-ResourceGroupName "TestRG" `
-Debug `
-Force `
-TemplateFile .\azuredeploy.bicep

New-AzResourceGroupDeployment -Name 'Charlie' `
    -ResourceGroupName $devCenterInput.resourceGroupName `
    -Debug `
    -Force `
    -TemplateFile .\devboxDefinition.bicep `
    -location: $devCenterInput.location `
    -dbDefName: $devCenterInput.devboxDefinitions[1].name `
    -devCenterName: $devCenterInput.name `
    -galleryName: $devCenterInput.devboxDefinitions[1].galleryName `
    -imageName: $devCenterInput.devboxDefinitions[1].imageName `
    -imageVersion: $devCenterInput.devboxDefinitions[1].imageVersion `
    -storage: $devCenterInput.devboxDefinitions[0].storage `
    -compute: $devCenterInput.devboxDefinitions[0].compute 
