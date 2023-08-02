#!/bin/bash
set -e

echo "Waiting on RBAC replication ($initialDelay)"
sleep $initialDelay

# az acr build --resource-group $acrResourceGroup \
#   --registry $acrName \
#   --image $taggedImageName $repo \
#   --file $dockerfilePath \
#   --platform $platform

kubectl create namespace alpha
kubectl apply -f azure-voting-app-redis\azure-vote-all-in-one-redis.yaml --namespace alpha