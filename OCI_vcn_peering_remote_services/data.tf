

data "oci_core_services" "services_r1" {
  provider = oci.r1
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

data "oci_core_services" "services_r2" {
  provider = oci.r2
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

data "oci_core_services" "services_r3" {
  provider = oci.r3
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

data "http" "region_cidr" {
  url = "https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}
