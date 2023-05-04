data "template_file" "jupyter_config" {
  template = file("config.jupyter")
  vars = {
    key = tls_private_key.ssh.private_key_pem
  }
}

data "template_file" "config" {
  template = file("config.hpc")
}


