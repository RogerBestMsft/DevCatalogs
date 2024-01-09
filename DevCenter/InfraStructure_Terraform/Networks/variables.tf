variable "devcenter_project_networks" {
  type = map(object({
	resource_group_name = string
	location = string
    cidr_block = list(string)
    subnets    = map(object({ 
		cidr_block = list(string) }))
  }))
}
# variable "devcenter_project_networks" {
# 	type							= list (object(
# 		{
# 			name					= string
# 			resource_group_name		= string
# 			devcenter_id			= string
# 			project_name			= string
# 			location				= string
# 			address_space			= string
# 			subnets					= list (object(
# 				{
# 					name			= string
# 					address_space	= string

# 				}
# 			))

# 		}
# 	))
# }


# # variable "vnets" {
# # 	type = map(object({
# #     	address_space = string
# #     	subnets = list(object({
# #       		subnet_name    = string
# #       		subnet_address = string
# #     	}))
# # 	}))
# # }