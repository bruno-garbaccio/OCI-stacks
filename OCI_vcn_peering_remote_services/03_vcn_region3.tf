# ------ Create a new VCN in region 3
resource oci_core_vcn r3-vcn {
  count = var.is_region3 ? 1 : 0
  provider       = oci.r3
  cidr_blocks    = [ var.r3_cidr_vcn ]
  compartment_id = var.r3_compartment_ocid
  display_name   = var.r3_name_vcn
  dns_label      = var.r3_name_vcn
}

# ------ Create a new Internet Gategay
resource oci_core_internet_gateway r3-ig {
  count = var.is_region3 ? 1 : 0
  provider       = oci.r3
  compartment_id = var.r3_compartment_ocid
  display_name   = "${var.r3_name_vcn}_igw"
  vcn_id         = oci_core_vcn.r3-vcn[count.index].id
}

# ------ Create a new Route Table for the public subnet
resource oci_core_route_table r3-pubnet-rt {
  count = var.is_region3 ? 1 : 0
  provider       = oci.r3
  compartment_id = var.r3_compartment_ocid
  vcn_id         = oci_core_vcn.r3-vcn[count.index].id
  display_name   = "${var.r3_name_vcn}_pubnet_rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.r3-ig[count.index].id
  }

  route_rules {
    destination       = var.r1_cidr_vcn
    network_entity_id = oci_core_drg.r3_drg[count.index].id
    description = "Route rule ro ${var.r1_name_vcn}"
  }

  route_rules {
    destination       = var.r2_cidr_vcn
    network_entity_id = oci_core_drg.r3_drg[count.index].id
    description = "Route rule ro ${var.r2_name_vcn}"
  }
  
  dynamic "route_rules" {
    for_each = local.oci_cidr_region1
    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      description = "addresses for ${var.region1} services"
      network_entity_id = oci_core_drg.r3_drg[count.index].id
    }
  }
  dynamic "route_rules" {
    for_each = local.oci_cidr_region2
    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      description = "addresses for ${var.region2} services"
      network_entity_id = oci_core_drg.r3_drg[count.index].id
    }
  }  
}

# ------ Create a new Route Table for the private subnet
resource oci_core_route_table r3-privnet-rt {
  count = var.is_region3 ? 1 : 0
  provider       = oci.r3
  compartment_id = var.r3_compartment_ocid
  vcn_id         = oci_core_vcn.r3-vcn[count.index].id
  display_name   = "${var.r3_name_vcn}_privnet_rt"

  route_rules {
    destination       = var.r1_cidr_vcn
    network_entity_id = oci_core_drg.r3_drg[count.index].id
    description = "Route rule ro ${var.r1_name_vcn}"
  }

  route_rules {
    destination       = var.r2_cidr_vcn
    network_entity_id = oci_core_drg.r3_drg[count.index].id
    description = "Route rule ro ${var.r2_name_vcn}"
  }

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.ng3[count.index].id
  } 
  route_rules {
    destination       = data.oci_core_services.services_r3.services[0]["cidr_block"]
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sg3[count.index].id
  } 
  dynamic "route_rules" {
    for_each = local.oci_cidr_region1
    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      description = "addresses for ${var.region1} services"
      network_entity_id = oci_core_drg.r3_drg[count.index].id
    }
  }
  dynamic "route_rules" {
    for_each = local.oci_cidr_region2
    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      description = "addresses for ${var.region2} services"
      network_entity_id = oci_core_drg.r3_drg[count.index].id
    }
  }   
}

# ------ Create a new security list to be used in the new public subnet
resource oci_core_security_list r3-pubnet-sl {
  count = var.is_region3 ? 1 : 0
  provider       = oci.r3
  compartment_id = var.r3_compartment_ocid
  display_name   = "${var.r3_name_vcn}_pubnet_sl"
  vcn_id         = oci_core_vcn.r3-vcn[count.index].id

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.r3_cidr_vcn
    description = "all Protocols to ${var.r3_name_vcn}"
  }
  ingress_security_rules {
    protocol = "all"
    source   = var.r2_cidr_vcn
    description = "all Protocols to ${var.r2_name_vcn}"
  }  
  ingress_security_rules {
    protocol = "all"
    source   = var.r1_cidr_vcn
    description = "all Protocols to ${var.r1_name_vcn}"
  }
  ingress_security_rules {
    protocol = "6" # tcp
    source   = var.authorized_ips

    tcp_options {
      min = 22
      max = 22
    }
  }
  # needed. See https://docs.cloud.oracle.com/iaas/Content/Network/Troubleshoot/connectionhang.htm?Highlight=MTU#Path
  ingress_security_rules {
    protocol = "1" # icmp
    source   = var.authorized_ips

    icmp_options {
      type = 3
      code = 4
    }
  }
}

# ------ Create a new security list to be used in the new private subnet
resource oci_core_security_list r3-privnet-sl {
  count = var.is_region3 ? 1 : 0
  provider       = oci.r3
  compartment_id = var.r3_compartment_ocid
  display_name   = "${var.r3_name_vcn}_privnet_sl"
  vcn_id         = oci_core_vcn.r3-vcn[count.index].id

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.r3_cidr_vcn
    description = "all Protocols to ${var.r3_name_vcn}"
  }
  ingress_security_rules {
    protocol = "all"
    source   = var.r2_cidr_vcn
    description = "all Protocols to ${var.r2_name_vcn}"
  }  
  ingress_security_rules {
    protocol = "all"
    source   = var.r1_cidr_vcn
    description = "all Protocols to ${var.r1_name_vcn}"
  }

  ingress_security_rules {
    protocol = "6" # tcp
    source   = var.authorized_ips

    tcp_options {
      min = 22
      max = 22
    }
  }
}

# ------ Create a public subnet in the new VCN
resource oci_core_subnet r3-pubnet {
  count = var.is_region3 ? 1 : 0
  provider            = oci.r3
  cidr_block          = var.r3_cidr_pubnet
  display_name        = "${var.r3_name_vcn}_pubnet"
  dns_label           = "public"
  compartment_id      = var.r3_compartment_ocid
  vcn_id              = oci_core_vcn.r3-vcn[count.index].id
  route_table_id      = oci_core_route_table.r3-pubnet-rt[count.index].id
  security_list_ids   = [oci_core_security_list.r3-pubnet-sl[count.index].id]
  dhcp_options_id     = oci_core_vcn.r3-vcn[count.index].default_dhcp_options_id
}

# ------ Create a private subnet in the new VCN
resource oci_core_subnet r3-privnet {
  count = var.is_region3 ? 1 : 0
  provider            = oci.r3
  cidr_block          = var.r3_cidr_privnet
  display_name        = "${var.r3_name_vcn}_privnet"
  dns_label           = "private"
  compartment_id      = var.r3_compartment_ocid
  vcn_id              = oci_core_vcn.r3-vcn[count.index].id
  route_table_id      = oci_core_route_table.r3-privnet-rt[count.index].id
  security_list_ids   = [oci_core_security_list.r3-privnet-sl[count.index].id]
  prohibit_public_ip_on_vnic = true
  dhcp_options_id     = oci_core_vcn.r3-vcn[count.index].default_dhcp_options_id
}

# ------ Create a Dynamic Routing Gateway (DRG) in the new VCN and attach it to the VCN
resource oci_core_drg r3_drg {
  count = var.is_region3 ? 1 : 0
  provider       = oci.r3
  compartment_id = var.r3_compartment_ocid
}

resource oci_core_drg_attachment r3_drg_attachment {
  count = var.is_region3 ? 1 : 0
  provider = oci.r3
  drg_id   = oci_core_drg.r3_drg[count.index].id
  network_details {
    id    = oci_core_vcn.r3-vcn[count.index].id
    type = "VCN"
    route_table_id = oci_core_route_table.r3-drg-rt[count.index].id
  }
}

# ------ Enable the remote VCN peering (region1-3 = acceptor)
resource oci_core_remote_peering_connection r1-3-acceptor {
  count = var.is_region3 ? 1 : 0
  provider       = oci.r1
  compartment_id = var.r1_compartment_ocid
  drg_id         = oci_core_drg.r1_drg.id
  display_name   = "remotePeeringConnectionR13"
}

# ------ Enable the remote VCN peering (region3-1 = requestor)
resource oci_core_remote_peering_connection r3-1-requestor {
  count = var.is_region3 ? 1 : 0
  provider         = oci.r3
  compartment_id   = var.r3_compartment_ocid
  drg_id           = oci_core_drg.r3_drg[count.index].id
  display_name     = "remotePeeringConnectionR31"
  peer_id          = oci_core_remote_peering_connection.r1-3-acceptor[count.index].id
  peer_region_name = var.region1
}

# ------ Enable the remote VCN peering (region2-3 = acceptor)
resource oci_core_remote_peering_connection r2-3-acceptor {
  count = var.is_region3 ? 1 : 0
  provider       = oci.r2
  compartment_id = var.r2_compartment_ocid
  drg_id         = oci_core_drg.r2_drg.id
  display_name   = "remotePeeringConnectionR23"
}

# ------ Enable the remote VCN peering (region32 = requestor)
resource oci_core_remote_peering_connection r3-2-requestor {
  count = var.is_region3 ? 1 : 0
  provider         = oci.r3
  compartment_id   = var.r3_compartment_ocid
  drg_id           = oci_core_drg.r3_drg[count.index].id
  display_name     = "remotePeeringConnectionR32"
  peer_id          = oci_core_remote_peering_connection.r2-3-acceptor[count.index].id
  peer_region_name = var.region2
}

# ----- Create NAT GW
resource "oci_core_nat_gateway" "ng3" {
  count = var.is_region3 ? 1 : 0
  provider       = oci.r3
  vcn_id   = oci_core_vcn.r3-vcn[count.index].id
  compartment_id = var.r3_compartment_ocid
  display_name   = "${var.r3_name_vcn}_nat-gateway"
}

# ----- Create Service GW
resource "oci_core_service_gateway" "sg3" {
  count = var.is_region3 ? 1 : 0
  provider       = oci.r3
  vcn_id         = oci_core_vcn.r3-vcn[count.index].id
  compartment_id = var.r3_compartment_ocid
  display_name   = "${var.r3_name_vcn}_service-gateway"
  route_table_id = oci_core_route_table.r3-sgw-rt[count.index].id

  services {
    service_id = data.oci_core_services.services_r3.services[0]["id"]
  }
}

# ----- Create region 3 DRG route table
resource oci_core_route_table r3-drg-rt {
  count = var.is_region3 ? 1 : 0
  provider       = oci.r3
  compartment_id = var.r3_compartment_ocid
  vcn_id         = oci_core_vcn.r3-vcn[count.index].id
  display_name   = "${var.r3_name_vcn}_drg_rt"

  route_rules {
    destination       = data.oci_core_services.services_r3.services[0]["cidr_block"]
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sg3[count.index].id
  }
}

# ----- Create region 3 SGW route table
resource oci_core_route_table r3-sgw-rt {
  count = var.is_region3 ? 1 : 0
  provider       = oci.r3
  compartment_id = var.r3_compartment_ocid
  vcn_id         = oci_core_vcn.r3-vcn[count.index].id
  display_name   = "${var.r3_name_vcn}_sgw_rt"

  route_rules {
    destination       = var.r1_cidr_vcn
    network_entity_id = oci_core_drg.r3_drg[count.index].id
    description = "CIDR range for ${var.r1_name_vcn}"
  }
  route_rules {
    destination       = var.r2_cidr_vcn
    network_entity_id = oci_core_drg.r3_drg[count.index].id
    description = "CIDR range for ${var.r2_name_vcn}"
  }  
}
