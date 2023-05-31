terraform init
terraform plan -state=$EnvironmentState -out=$EnvironmentPlan -var-file="$EnvironmentVars" -var "resource_group_name=$ENVIRONMENT_RESOURCE_GROUP_NAME"
terraform apply -auto-approve -state=$EnvironmentState $EnvironmentPlan
az storage account create --name billybob --resource-group $ENVIRONMENT_RESOURCE_GROUP_NAME --location eastus --dns-endpoint-type AzureDnsZone