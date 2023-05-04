output "jupyter" {
  value = "${local.host}"
}

resource "local_file" "key" {
  depends_on = [null_resource.cluster]
  content = "${tls_private_key.ssh.private_key_pem}"
  filename = "/tmp/key"
  file_permission = "600"
}



data "external" "token_file" {
  depends_on = [local_file.key]
  program = [
    "ssh",
    "-y",
    "-o StrictHostKeyChecking=no",
    "-i",
    "/tmp/key",
    "${var.jupyter_username}@${local.host}",
    "/opt/oci-hpc/bin/json.sh"
  ]
}


output "token" {
  depends_on = [data.external.token_file]
  value = data.external.token_file.result.token
  
}

output "url" {
  depends_on = [data.external.token_file]
  value = "${local.host}:8888/${chomp(data.external.token_file.result.token)}"
}



