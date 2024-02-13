#$token = az account get-access-token --subscription 572b41e6-5c44-486a-84d2-01d6202774ac

# Get Azure Subscription ID
$subscriptionId="572b41e6-5c44-486a-84d2-01d6202774ac"

#Get Azure Access Token to authorize HTTP requests
$azureAccessToken=$(az account get-access-token --query accessToken -o tsv)
#Write-Output $azureAccessToken
# List all Resource Groups
# curl -sL -H "authorization: bearer $azureAccessToken" -H "content-type: application/json" "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups?api-version=2020-01-01"
$headers = @{
	"content-type" = "application/json"
	"Authorization" = "Bearer $azureAccessToken"
}

Invoke-WebRequest -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups?api-version=2020-01-01" -Headers $headers -UseBasicParsing 