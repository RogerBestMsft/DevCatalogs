#!/bin/bash
az login --identity
curl -X PUT -H "Authorization: Bearer $(az account get-access-token --query accessToken -o tsv)" -H "Content-Type: application/json" -d '{"location": "eastus"}' https://management.azure.com/subscriptions/572b41e6-5c44-486a-84d2-01d6202774ac/resourceGroups/AAGolf?api-version=2020-01-01