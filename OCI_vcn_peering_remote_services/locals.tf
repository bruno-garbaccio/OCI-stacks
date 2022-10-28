
locals {
  raw_data     = jsondecode(data.http.region_cidr.response_body)
  myregion = [for exp in local.raw_data.regions : exp.region]
  mycidrs = [for exp in local.raw_data.regions : exp.cidrs]
  oci_cidr_region1 = [for exp in "${element(local.mycidrs, "${index(local.myregion, var.region1)}")}" : exp.cidr]
  oci_cidr_region2 = [for exp in "${element(local.mycidrs, "${index(local.myregion, var.region2)}")}" : exp.cidr]
  oci_cidr_region3 = var.is_region3 ? [for exp in "${element(local.mycidrs, "${index(local.myregion, var.region3)}")}" : exp.cidr] : []
  list_vcn3 = var.is_region3 ? [var.r3_cidr_vcn] : []
}

