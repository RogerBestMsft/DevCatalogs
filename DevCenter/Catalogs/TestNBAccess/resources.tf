
data "external" "checktoken" {
    program = ["bash", "${path.root}/CheckToken.sh"]
}
