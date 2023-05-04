locals { 
// display names of instances 
  jupyter_ocpus = length(regexall(".*VM.*.*Flex$", var.jupyter_shape)) > 0 ? var.jupyter_ocpus_denseIO_flex : var.jupyter_ocpus
// ips of the instances

// vcn id derived either from created vcn or existing if specified
  vcn_id = var.use_existing_vcn ? var.vcn_id : element(concat(oci_core_vcn.vcn.*.id, [""]), 0)

// subnet id derived either from created subnet or existing if specified
//  subnet_id = var.use_existing_vcn ? var.private_subnet_id : element(concat(oci_core_subnet.private-subnet.*.id, [""]), 0)
  subnet_id = var.private_deployment ? var.use_existing_vcn ? var.private_subnet_id : element(concat(oci_core_subnet.private-subnet.*.id, [""]), 1) : var.use_existing_vcn ? var.private_subnet_id : element(concat(oci_core_subnet.private-subnet.*.id, [""]), 0)

// subnet id derived either from created subnet or existing if specified
// jupyter_subnet_id = var.use_existing_vcn ? var.public_subnet_id : element(concat(oci_core_subnet.public-subnet.*.id, [""]), 0)
  jupyter_subnet_id = var.private_deployment ? var.use_existing_vcn ? var.public_subnet_id : element(concat(oci_core_subnet.private-subnet.*.id, [""]), 0) : var.use_existing_vcn ? var.public_subnet_id : element(concat(oci_core_subnet.public-subnet.*.id, [""]), 0)
  
//  jupyter_image = var.use_standard_image ? oci_core_app_catalog_subscription.jupyter_mp_image_subscription[0].listing_resource_id : local.custom_jupyter_image_ocid

  jupyter_name = var.use_custom_name ? var.jupyter_name : random_pet.name.id

  is_jupyter_flex_shape = length(regexall(".*VM.*.*Flex$", var.jupyter_shape)) > 0 ? [local.jupyter_ocpus]:[]


  jupyter_mount_ip = var.jupyter_block ? element(concat(oci_core_volume_attachment.jupyter_volume_attachment.*.ipv4, [""]), 0) : "none"



// Cluster OCID


  host = var.private_deployment ? data.oci_resourcemanager_private_endpoint_reachable_ip.private_endpoint_reachable_ip[0].ip_address : oci_core_instance.jupyter.public_ip
  jupyter_bool_ip = var.private_deployment ? false : true
  jupyter_subnet = var.private_deployment ? oci_core_subnet.private-subnet : oci_core_subnet.private-subnet 
  private_subnet_cidr = var.private_deployment ? [var.public_subnet, var.private_subnet] : [var.private_subnet]

}
