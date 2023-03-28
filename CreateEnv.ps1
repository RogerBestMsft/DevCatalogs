# Using the DevCenter cli to create environments
param(
  [Parameter(Mandatory=$false,
  HelpMessage="Subscription Id")]
  [String]
  $SubscriptionId = "572b41e6-5c44-486a-84d2-01d6202774ac",

  [Parameter(Mandatory=$false,
  HelpMessage="DevCenter name")]
  [String]
  $DevCenterName = "TRDevCenter",

  [Parameter(Mandatory=$false,
  HelpMessage="Project Name")]
  [String]
  $ProjectName = "WebAppProject",

  [Parameter(Mandatory=$false,
  HelpMessage="Catalog Name")]
  [String]
  $CatalogName = "DevCatalog",

  [Parameter(Mandatory=$false,
  HelpMessage="CatalogItem Name")]
  [String]
  $CatalogItemName = "BasicWebAppContainer",

  [Parameter(Mandatory=$false,
  HelpMessage="Environment Type Name")]
  [String]
  $EnvironmentTypeName = "BasicWebApp",

  [Parameter(Mandatory=$false,
  HelpMessage="Environment Name")]
  [String]
  $EnvironmentName = "BWACharlie"

)
# Assume Az Cli is installed

#az login
az account set --subscription $SubscriptionId
# Check for devcenter extension
az extension show --name devcenter | Out-Null
if ($LASTEXITCODE) {
    Write-Host "Installing DevCenter extension."
    az extension add --name devcenter
}

$catalogItem = az devcenter dev catalog-item list --dev-center-name $DevCenterName --project-name $ProjectName | ConvertFrom-Json | Where-Object {$_.name -eq $CatalogItemName}

If (!$catalogItem) {
    Write-Host "Unable to find catalog item $CatalogItemName"
    exit
}

$environmentType = az devcenter dev environment-type list --dev-center-name $DevCenterName --project-name $ProjectName | ConvertFrom-Json | Where-Object {$_.name -eq $EnvironmentTypeName}

If (!$environmentType) {
    Write-Host "Unable to find environment type $EnvironmentTypeName"
    exit
}

#az graph query -q "Resources | where type =~ 'microsoft.devcenter/projects'" -o table
#az graph query -q "Resources | where type =~ 'microsoft.devcenter/projects'" | ConvertFrom-Json | Select-Object Data
#$a = az graph query -q "Resources | where type =~ 'microsoft.devcenter/projects'"  | ConvertFrom-Json -Depth 20 | Select-Object Data | ConvertTo-Json -Depth 20 

#$params = @{\"name\":\"rbestaaa\",\"dockerRegistryUsername\":\"rbest\",\"dockerRegistryPassword\":\"Ode1ode1234\"}
$params = @{"name" = "rbestaaa"; "dockerRegistryUsername" = "rbest";  "dockerRegistryPassword" = "ode#1ode1234"}

az devcenter dev environment create `
    --dev-center-name $DevCenterName `
    --project-name $ProjectName `
    --environment-name $EnvironmentName `
    --environment-type $EnvironmentTypeName `
    --catalog-item-name $CatalogItemName `
    --catalog-name $CatalogName

    #--parameters $params | ConvertTo-Json

