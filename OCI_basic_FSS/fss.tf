resource "oci_file_storage_file_system" "FSS" {
  availability_domain         = var.fss_ad
  compartment_id              = var.fss_compartment
  display_name                = var.fss_name  
  }

resource "oci_file_storage_file_system" "FSS_home" {
  count          =       var.home_fss ? 1 : 0
  availability_domain         = var.fss_ad
  compartment_id              = var.fss_compartment
  display_name                = "${var.fss_name }-home"  
  }

resource "oci_file_storage_mount_target" "FSSMountTarget" {
  availability_domain = var.fss_ad 
  compartment_id      = var.fss_compartment
  subnet_id           = var.private_subnet_id
  display_name        = "${var.fss_name}-mt"  
  hostname_label      = "fileserver"
}

resource "oci_file_storage_export" "FSSExport" {
  export_set_id  = oci_file_storage_mount_target.FSSMountTarget.export_set_id
  file_system_id = oci_file_storage_file_system.FSS.id
  path           = var.nfs_source_path  
  export_options {
    source = data.oci_core_vcn.vcn.cidr_block
    access = "READ_WRITE"
    identity_squash = "NONE"
  }
}

resource "oci_file_storage_export" "FSSExport_home" {
  count          = var.home_fss ? 1 : 0
  export_set_id  = oci_file_storage_mount_target.FSSMountTarget.export_set_id
  file_system_id = oci_file_storage_file_system.FSS_home.0.id
  path           = "/home"
  export_options {
    source = data.oci_core_vcn.vcn.cidr_block
    access = "READ_WRITE"
    identity_squash = "NONE"
  }
}


