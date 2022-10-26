# -------- get the list of available ADs
data oci_identity_availability_domains r2ADs {
  provider       = oci.r2
  compartment_id = var.tenancy_ocid
}

# ------ Create a new VCN in region 2
resource oci_core_vcn r2-vcn {
  provider       = oci.r2
  cidr_blocks    = [ var.r2_cidr_vcn ]
  compartment_id = var.r2_compartment_ocid
  display_name   = var.r2_name_vcn
  dns_label      = "vcn2"
}

# ------ Create a new Internet Gategay
resource oci_core_internet_gateway r2-ig {
  provider       = oci.r2
  compartment_id = var.r2_compartment_ocid
  display_name   = "${var.r2_name_vcn}_igw"
  vcn_id         = oci_core_vcn.r2-vcn.id
}

# ------ Create a new Route Table for the public subnet
resource oci_core_route_table r2-pubnet-rt {
  provider       = oci.r2
  compartment_id = var.r2_compartment_ocid
  vcn_id         = oci_core_vcn.r2-vcn.id
  display_name   = "${var.r2_name_vcn}_pubnet_rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.r2-ig.id
  }

  route_rules {
    destination       = var.r1_cidr_vcn
    network_entity_id = oci_core_drg.r2_drg.id
  }
  dynamic "route_rules" {
    for_each = local.oci_cidr_region1
    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      description = "addresses for ${var.region1} services"
      network_entity_id = oci_core_drg.r2_drg.id
    }
  }
}

# ------ Create a new Route Table for the private subnet
resource oci_core_route_table r2-privnet-rt {
  provider       = oci.r2
  compartment_id = var.r2_compartment_ocid
  vcn_id         = oci_core_vcn.r2-vcn.id
  display_name   = "${var.r2_name_vcn}_privnet_rt"

  route_rules {
    destination       = var.r1_cidr_vcn
    network_entity_id = oci_core_drg.r2_drg.id
  }
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.ng2.id
  } 
  route_rules {
    destination       = data.oci_core_services.services_r2.services[0]["cidr_block"]
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sg2.id
  } 
  dynamic "route_rules" {
    for_each = local.oci_cidr_region1
    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      description = "addresses for ${var.region1} services"
      network_entity_id = oci_core_drg.r2_drg.id
    }
  }
}

# ------ Create a new security list to be used in the new public subnet
resource oci_core_security_list r2-pubnet-sl {
  provider       = oci.r2
  compartment_id = var.r2_compartment_ocid
  display_name   = "${var.r2_name_vcn}_pubnet_sl"
  vcn_id         = oci_core_vcn.r2-vcn.id

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.r2_cidr_vcn
  }
  ingress_security_rules {
    protocol = "all"
    source   = var.r1_cidr_vcn
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
resource oci_core_security_list r2-privnet-sl {
  provider       = oci.r2
  compartment_id = var.r2_compartment_ocid
  display_name   = "${var.r2_name_vcn}_privnet_sl"
  vcn_id         = oci_core_vcn.r2-vcn.id

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.r1_cidr_vcn
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.r2_cidr_vcn
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
resource oci_core_subnet r2-pubnet {
  provider            = oci.r2
  cidr_block          = var.r2_cidr_pubnet
  display_name        = "${var.r2_name_vcn}_pubnet"
  dns_label           = "public"
  compartment_id      = var.r2_compartment_ocid
  vcn_id              = oci_core_vcn.r2-vcn.id
  route_table_id      = oci_core_route_table.r2-pubnet-rt.id
  security_list_ids   = [oci_core_security_list.r2-pubnet-sl.id]
  dhcp_options_id     = oci_core_vcn.r2-vcn.default_dhcp_options_id
}

# ------ Create a private subnet in the new VCN
resource oci_core_subnet r2-privnet {
  provider            = oci.r2
  cidr_block          = var.r2_cidr_privnet
  display_name        = "${var.r2_name_vcn}_privnet"
  dns_label           = "private"
  compartment_id      = var.r2_compartment_ocid
  vcn_id              = oci_core_vcn.r2-vcn.id
  route_table_id      = oci_core_route_table.r2-privnet-rt.id
  security_list_ids   = [oci_core_security_list.r2-privnet-sl.id]
  prohibit_public_ip_on_vnic = true
  dhcp_options_id     = oci_core_vcn.r2-vcn.default_dhcp_options_id
}

# ------ Create a Dynamic Routing Gateway (DRG) in the new VCN and attach it to the VCN
resource oci_core_drg r2_drg {
  provider       = oci.r2
  compartment_id = var.r2_compartment_ocid
}

resource oci_core_drg_attachment r2_drg_attachment {
  provider = oci.r2
  drg_id   = oci_core_drg.r2_drg.id
  network_details {
    id    = oci_core_vcn.r2-vcn.id
    type = "VCN"
    route_table_id = oci_core_route_table.r2-drg-rt.id
  }
}

# ------ Enable the remote VCN peering (region2 = requestor)
resource oci_core_remote_peering_connection r2-requestor {
  provider         = oci.r2
  compartment_id   = var.r2_compartment_ocid
  drg_id           = oci_core_drg.r2_drg.id
  display_name     = "remotePeeringConnectionR2"
  peer_id          = oci_core_remote_peering_connection.r1-acceptor.id
  peer_region_name = var.region1
}

# ----- Create NAT GW
resource "oci_core_nat_gateway" "ng2" {
  provider       = oci.r2
  vcn_id   = oci_core_vcn.r2-vcn.id
  compartment_id = var.r2_compartment_ocid
  display_name   = "${var.r2_name_vcn}_nat-gateway"
}

# ----- Create Service GW
resource "oci_core_service_gateway" "sg2" {
  provider       = oci.r2
  vcn_id         = oci_core_vcn.r2-vcn.id
  compartment_id = var.r2_compartment_ocid
  display_name   = "${var.r2_name_vcn}_service-gateway"
  route_table_id = oci_core_route_table.r2-sgw-rt.id

  services {
    service_id = data.oci_core_services.services_r2.services[0]["id"]
  }
}

# ----- Create region 2 DRG route table
resource oci_core_route_table r2-drg-rt {
  provider       = oci.r2
  compartment_id = var.r2_compartment_ocid
  vcn_id         = oci_core_vcn.r2-vcn.id
  display_name   = "${var.r2_name_vcn}_drg_rt"

  route_rules {
    destination       = data.oci_core_services.services_r2.services[0]["cidr_block"]
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sg2.id
  }
}

# ----- Create region 2 SGW route table
resource oci_core_route_table r2-sgw-rt {
  provider       = oci.r2
  compartment_id = var.r2_compartment_ocid
  vcn_id         = oci_core_vcn.r2-vcn.id
  display_name   = "${var.r2_name_vcn}_sgw_rt"

  route_rules {
    destination       = var.r1_cidr_vcn
    network_entity_id = oci_core_drg.r2_drg.id
  }
}