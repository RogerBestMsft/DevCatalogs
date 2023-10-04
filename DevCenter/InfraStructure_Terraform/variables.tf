variable "devcenter_object" {
	type 					= object(
		{
			name			= string
			resourcegroup 	= string
			location		= string
			identity		= string
			keyvault		= string
			imagegallery	= string
		}
	)
}

variable "devcenter_catalogs" {
	type 					= object(
		{
			name 			= string
			repoBranch		= string
			repoType		= string
			repoUri			= string
			repoAccess		= string
			repoPath		= string
		}
	)
}

variable "devcenter_environment_types" {
	type 					= list(string)
}

variable "devcenter_devbox_definitions" {
	type 					= list(object(
		{
			name 			= string
			location		= string
			hibernate		= string
			imageId			= string
			storageType		= string
			sku_Name		= string
		}
	)) 

}

variable "project_objects" {
	type 					= list(object(
		{
	  		name 			= string
			location		= string
			resourcegroup	= string
			description		= string
			maxDevBoxes     = number		
		}
	))
}


# variable "tags" {
# 	type = list(object({
# 	  tag1 = string
# 	}))
# }