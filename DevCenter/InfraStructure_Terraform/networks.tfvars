devcenter_project_networks = {
    private = {
        resource_group_name = "VanArsdelLTDAGAlphaRGA"
        location = "eastus"
        cidr_block = ["19.0.0.0/16"]
        subnets = {
            "db1" = {
            cidr_block = ["19.0.0.0/24"]
            }
            "db2" = {
            cidr_block = ["19.0.1.0/24"]
            }
        }
    }
    public = {
        resource_group_name = "VanArsdelLTDAGAlphaRGA"
        location = "eastus"
        cidr_block = ["19.1.0.0/16"]
        subnets = {
            "webserver" = {
            cidr_block = ["19.1.0.0/24"]
            }
            "email_server" = {
            cidr_block = ["19.1.1.0/24"]
            }
        }
    }
    dmz = {
        resource_group_name = "VanArsdelLTDAGAlphaRGB"
        location = "eastus"
        cidr_block = ["19.2.0.0/16"]
        subnets = {
            "firewall" = {
            cidr_block = ["19.2.0.0/24"]
            }
        }
    }
//  }
}

# devcenter_project_networks = [{
#         name = "AlphaVnet"
#         resource_group_name = "AlphaVnetRG"
#         devcenter_id = "/subscriptions/572b41e6-5c44-486a-84d2-01d6202774ac/resourceGroups/VanArsdelLTDAGRG/providers/Microsoft.DevCenter/devcenters/VanArsdelLTDAG"
#         project_name = "AlphaProject"
#         location = "eastus"
#         address_space = "15.0.0/16"
#         }]
#         subnets = [{
#             name = "AlphaVnetSubA"
#             address_space = "15.0.0/24"
#         },{
#             name = "AlphaVnetSubB"
#             address_space = "15.1.0/24"
#         }
#         ]
#     }
# ]
