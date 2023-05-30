terraform init
terraform plan -state=$EnvironmentState -out=$EnvironmentPlan -var-file="$EnvironmentVars" -var "resource_group_name=TestRG"
terraform apply -auto-approve -state=$EnvironmentState $EnvironmentPlan