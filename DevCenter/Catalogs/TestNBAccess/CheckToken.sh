#!/bin/bash
subscriptionId="572b41e6-5c44-486a-84d2-01d6202774ac"

azureAccessToken=$(az account get-access-token --query accessToken -o tsv)
curl -sL -H "authorization: bearer $azureAccessToken" -H "content-type: application/json" "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups?api-version=2020-01-01"
