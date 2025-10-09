/*
  Shared utility functions for referencing existing Azure resources.
  These functions help other modules reference resources by name for role assignments and configurations.
*/

/*
  Gets a reference to an existing Key Vault resource by name
  Usage: In other modules that need to assign roles to the Key Vault
*/
@export()
func getKeyVaultReference(keyVaultName string) object => {
  existing: true
  type: 'Microsoft.KeyVault/vaults@2023-07-01'
  name: keyVaultName
}

/*
  Gets the Key Vault Secrets User role definition ID
  This is a well-known Azure built-in role
*/
@export()
func getKeyVaultSecretsUserRoleId() string => '4633458b-17de-408a-b874-0445c86b69e6'
