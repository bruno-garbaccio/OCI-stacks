locals { 
// display names of instances 
  cluster_instances_ids = var.cluster_network ? data.oci_core_instance.cluster_network_instances.*.id : data.oci_core_instance.instance_pool_instances.*.id
  cluster_instances_names = var.cluster_network ? data.oci_core_instance.cluster_network_instances.*.display_name : data.oci_core_instance.instance_pool_instances.*.display_name
  image_ocid = var.unsupported ? var.image_ocid : var.image 

  shape = var.cluster_network ? var.cluster_network_shape : var.instance_pool_shape
  instance_pool_ocpus = local.shape == "VM.DenseIO.E4.Flex" ? var.instance_pool_ocpus_denseIO_flex : var.instance_pool_ocpus
// ips of the instances
  cluster_instances_ips = var.cluster_network ? data.oci_core_instance.cluster_network_instances.*.private_ip : data.oci_core_instance.instance_pool_instances.*.private_ip

// subnet id derived either from created subnet or existing if specified
  subnet_id = var.private_deployment ? var.use_existing_vcn ? var.private_subnet_id : element(concat(oci_core_subnet.private-subnet.*.id, [""]), 1) : var.use_existing_vcn ? var.private_subnet_id : element(concat(oci_core_subnet.private-subnet.*.id, [""]), 0)

// subnet id derived either from created subnet or existing if specified
  bastion_subnet_id = var.private_deployment ? var.use_existing_vcn ? var.public_subnet_id : element(concat(oci_core_subnet.private-subnet.*.id, [""]), 0) : var.use_existing_vcn ? var.public_subnet_id : element(concat(oci_core_subnet.public-subnet.*.id, [""]), 0)
  cluster_name = var.use_custom_name ? var.cluster_name : random_pet.name.id

  cluster_network_image = var.use_marketplace_image ? oci_core_app_catalog_subscription.mp_image_subscription[0].listing_resource_id : local.image_ocid

  instance_pool_image = ! var.cluster_network && var.use_marketplace_image ? oci_core_app_catalog_subscription.mp_image_subscription[0].listing_resource_id : local.image_ocid

//  image = (var.cluster_network && var.use_marketplace_image == true) || (var.cluster_network == false && var.use_marketplace_image == false) ? var.image : data.oci_core_images.linux.images.0.id

//  is_bastion_flex_shape = length(regexall(".*VM.*.*Flex$", var.bastion_shape)) > 0 ? [var.bastion_ocpus]:[]
  is_instance_pool_flex_shape = length(regexall(".*VM.*.*Flex$", var.instance_pool_shape)) > 0 ? [local.instance_pool_ocpus]:[]
  
//  bastion_mount_ip = var.bastion_block ? element(concat(oci_core_volume_attachment.bastion_volume_attachment.*.ipv4, [""]), 0) : "none"

  scratch_nfs_type = var.cluster_network ? var.scratch_nfs_type_cluster : var.scratch_nfs_type_pool 

  iscsi_ip = var.cluster_network ? element(concat(oci_core_volume_attachment.cluster_network_volume_attachment.*.ipv4, [""]), 0) : element(concat(oci_core_volume_attachment.instance_pool_volume_attachment.*.ipv4, [""]), 0)

  mount_ip = local.scratch_nfs_type == "block" ? local.iscsi_ip : "none" 

  timeout_per_batch= var.cluster_network ? var.use_multiple_ads ? 15 : 30 : var.use_multiple_ads ? 6 : 15
  timeout_ip = join("",[ (( var.node_count - ( var.node_count % 20 ) )/20 + 1 ) * local.timeout_per_batch,"m"])
}
