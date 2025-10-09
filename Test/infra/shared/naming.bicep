/*
  Functions supporting consistent application of naming conventions for various Azure resources. Edit this file to modify how the various resource names are resolved. 
  Centralizing the handling of naming across the solution helps to ensure that resources are easily identifiable and organized. 
  
  Notable details:
  - Normalized Name:
    - Provides a function to normalize names by converting them to lowercase and removing spaces.
  - get{resource_name}Name:
    - Provides a function to generate a name for a specific resource type. Presently, this is based on a prefix and the normalized lowercase name with no spaces.
      - Example: Where 'WinGit' is specified as the name, the getResourceGroupName function would return 'rg-wingit'.
*/

@export()
func getNormalizedName(name string) string => '${replace(toLower(name), ' ', '')}'

@export()
func getResourceGroupName(name string) string => 'rg-${getNormalizedName(name)}'

@export()
func getFunctionAppName(name string) string => 'func-${getNormalizedName(name)}'

@export()
func getStorageAccountName(name string) string => 'st${replace(replace(toLower(name), ' ', ''), '-', '')}'

@export()
func getAppInsightsName(name string) string => 'ai-${getNormalizedName(name)}'

@export()
func getAppServicePlanName(name string) string => 'asp-${getNormalizedName(name)}'

@export()
func getKeyVaultName(name string, qualifier string, referenceId string) string => take('kv-${getNormalizedName(name)}-${getNormalizedName(qualifier)}-${uniqueString(referenceId)}', 24)

@export()
func getLogAnalyticsWorkspaceName(name string) string => 'law-${getNormalizedName(name)}'

@export()
func getRedisCacheName(name string) string => 'redis-${getNormalizedName(name)}'

@export()
func getVirtualNetworkName(name string) string => 'vnet-${getNormalizedName(name)}'

@export()
func getNetworkSecurityGroupName(name string, suffix string) string => 'nsg-${getNormalizedName(name)}-${suffix}'

@export()
func getPrivateEndpointName(name string, service string) string => 'pe-${getNormalizedName(name)}-${service}'

@export()
func getPrivateDnsZoneName(service string) string => 'privatelink.${service}'
