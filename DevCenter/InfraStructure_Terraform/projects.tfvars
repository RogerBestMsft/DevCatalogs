project_object = [{
    name = "VanArsdelLTDAGAlpha"
    description = "Test project Alpha"
    resourcegroup = "VanArsdelLTDAGAlphaRG"
    location = "eastus"
    identity = "SystemAssigned"
    subscriptionId = "<SubID>"
    devboxLimits = 0
    devCenterId = "<DCID>"
    environmentTypes = [{
        type = "Dev"
        systemId = true
        roles = "Contributor"
    }]
}]

# project_environmentTypes = [{
#     type = "Dev"
#     subscriptionId = "<SubID>"
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