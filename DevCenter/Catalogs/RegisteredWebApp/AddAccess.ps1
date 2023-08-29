$APPLICATIONDEVELOPER_ROLEID="cf1c38e5-3621-4004-a7cb-879624dced7c"
$APPLICATIONOWNER_ROLEID="9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
$PRINCIPALID="adbd1d50-4e84-45f4-8399-01c3df420dbd"

$body = (@{
	"@odata.type" = "#microsoft.graph.unifiedRoleAssignment";
	directoryScopeId = "/";
	principalId = "$($PRINCIPALID)";
	roleDefinitionId = "$($APPLICATIONDEVELOPER_ROLEID)";
  } | ConvertTo-Json -Compress).Replace('"', '\"')


az rest --method post `
	--uri "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments" `
	--headers "{ 'content-type': 'application/json' }" `
	--body $body `
	--only-show-errors `
	--output none
