
resource "null_resource" "checktoken" {
  provisioner "local-exec" {
    command = "az account get-access-token --query accessToken -o tsv"
    interpreter = ["powershell"]
  }
}
