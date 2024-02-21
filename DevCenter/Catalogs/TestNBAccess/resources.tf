
resource "null_resource" "checktoken" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash"]
    command = "${path.module}/CheckToken.sh"
  }
}
