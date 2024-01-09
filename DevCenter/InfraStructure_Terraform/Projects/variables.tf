variable "project_object" {
	type 					= list(object(
		{
			name			= string
            description     = string
			resourcegroup 	= string
			location		= string
			identity		= string
            subscriptionId  = string
            devboxLimits    = number
            devCenterId     = string
            environmentTypes = list(object({
                type = string
                systemId = bool
                roles = string
            }))
		}
	))
}

# variable "project_environmentTypes" {
# 	type 					= list(object(
# 		{
# 			type 		    	= string
# 			subscriptionId		= string
# 			systemId		    = bool
# 			roles			    = string
# 		}
# 	))
# } 

variable "project_devbox_pools" {
	type 					= list(object(
		{
			name 		    	= string
			definition		    = string
			networkConnection	= string
			localAdmin		    = bool
            autoStop            = string
            stopTime            = string
            timeZone            = string
		}
	))
} 
