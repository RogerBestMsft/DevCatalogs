project_object = [{
    name = "VanArsdelLTDAGAlpha"
    description = "Test project Alpha"
    resourcegroup = "VanArsdelLTDAGAlphaRG"
    location = "eastus"
    identity = "SystemAssigned"
    subscriptionId = "572b41e6-5c44-486a-84d2-01d6202774ac"
    devboxLimits = 0
    devCenterId = "/subscriptions/572b41e6-5c44-486a-84d2-01d6202774ac/resourceGroups/VanArsdelLTDAGRG/providers/Microsoft.DevCenter/devcenters/VanArsdelLTDAG"
    environmentTypes = [{
        type = "Dev"
        systemId = true
        roles = "Contributor"
    }]
}]

# project_environmentTypes = [{
#     type = "Dev"
#     subscriptionId = "572b41e6-5c44-486a-84d2-01d6202774ac"
#     systemId = true
#     roles = "Contributor"
# }]

project_devbox_pools = [{
    name = "TestPoolAlpha"
    definition = "DefinitionBravo"
    networkConnection = "xxxx"
    localAdmin = true
    autoStop = "0"
    stopTime = "0"
    timeZone = "0"
}]