resource "random_pet" "name" {
  length = 2
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

data "oci_core_services" "services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}







data "oci_core_vcn" "vcn" { 
  vcn_id = local.vcn_id
} 
data "oci_core_subnet" "private_subnet" { 
  subnet_id = local.subnet_id 
}

data "oci_core_subnet" "public_subnet" { 
  subnet_id = local.jupyter_subnet_id
} 



data "oci_resourcemanager_private_endpoint_reachable_ip" "private_endpoint_reachable_ip" {
    #Required
    count = var.private_deployment ? 1 : 0
    private_endpoint_id = oci_resourcemanager_private_endpoint.rms_private_endpoint[0].id
    private_ip = tostring(oci_core_instance.jupyter.private_ip)
}

