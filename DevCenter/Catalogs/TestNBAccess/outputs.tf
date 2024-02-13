# output "random_output" {
#     value = random_integer.ResourceSuffix
# }

output "checkrg_output" {
    value = terraform_data.checktoken.output
}