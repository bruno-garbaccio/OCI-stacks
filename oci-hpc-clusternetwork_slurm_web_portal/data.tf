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
data "oci_core_cluster_network_instances" "cluster_network_instances" {
  count = var.cluster_network && var.node_count > 0 ? 1 : 0
  cluster_network_id = oci_core_cluster_network.cluster_network[0].id
  compartment_id     = var.targetCompartment
}

data "oci_core_instance_pool_instances" "instance_pool_instances" {
  count = ( ! var.cluster_network ) && ( var.node_count > 0 ) ? 1 : 0
  instance_pool_id = oci_core_instance_pool.instance_pool[0].id
  compartment_id     = var.targetCompartment
}

data "oci_core_instance" "cluster_network_instances" {
  count       = var.cluster_network && var.node_count > 0 ? var.node_count : 0
  instance_id = data.oci_core_cluster_network_instances.cluster_network_instances[0].instances[count.index]["id"]
}

data "oci_core_instance" "instance_pool_instances" {
  count       = var.cluster_network || var.node_count == 0 ? 0 : var.node_count
  instance_id = data.oci_core_instance_pool_instances.instance_pool_instances[0].instances[count.index]["id"]
}

data "oci_core_vcn" "vcn" { 
  vcn_id = local.vcn_id
} 
data "oci_core_subnet" "private_subnet" { 
  subnet_id = local.subnet_id 
}

data "oci_core_subnet" "public_subnet" { 
  subnet_id = local.bastion_subnet_id
} 

data "oci_core_images" "linux" {
  compartment_id = var.targetCompartment
  operating_system = "Oracle Linux"
  operating_system_version = "7.9"
  filter {
    name = "display_name"
    values = ["^([a-zA-z]+)-([a-zA-z]+)-([\\.0-9]+)-([\\.0-9-]+)$"]
    regex = true
  }
}

data "oci_resourcemanager_private_endpoint_reachable_ip" "private_endpoint_reachable_ip" {
    #Required
    count = var.private_deployment ? 1 : 0
    private_endpoint_id = oci_resourcemanager_private_endpoint.rms_private_endpoint[0].id
    private_ip = tostring(oci_core_instance.bastion.private_ip)
}

data "oci_resourcemanager_private_endpoint_reachable_ip" "private_endpoint_reachable_ip_backup" {
    #Required
    count = (var.private_deployment && var.slurm_ha) ? 1 : 0
    private_endpoint_id = oci_resourcemanager_private_endpoint.rms_private_endpoint[0].id
    private_ip = tostring(oci_core_instance.backup[0].private_ip)
}

data "oci_resourcemanager_private_endpoint_reachable_ip" "private_endpoint_reachable_ip_login" {
    #Required
    count = (var.private_deployment && var.login_node) ? 1 : 0
    private_endpoint_id = oci_resourcemanager_private_endpoint.rms_private_endpoint[0].id
    private_ip = tostring(oci_core_instance.login[0].private_ip)
}

data "oci_objectstorage_namespace" "namespace" {
    compartment_id = var.targetCompartment
}

data "oci_identity_compartment" "compartment" {
    id = var.targetCompartment
}

data "oci_identity_user" "user" {
    user_id = var.current_user_ocid
}
data "oci_artifacts_container_repository" "container_repo" {
    count = var.web_submission_portal ? 1 : 0
    repository_id = local.registry_id
}


data "oci_kms_vault" "vault" {
    count = var.web_submission_portal ? 1 : 0
    vault_id = local.vault_id
}

data "oci_kms_key" "master_key" {
    count = var.web_submission_portal ? 1 : 0
    key_id = local.master_key_id
    management_endpoint = data.oci_kms_vault.vault[0].management_endpoint
}

data "oci_identity_regions" "regions" {
}