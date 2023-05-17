terraform init
terraform plan -state=$EnvironmentState -out=$EnvironmentPlan -var-file="$EnvironmentVars" -var "resource_group_name=$ENVIRONMENT_RESOURCE_GROUP_NAME"
terraform apply -auto-approve -state=$EnvironmentState $EnvironmentPlan