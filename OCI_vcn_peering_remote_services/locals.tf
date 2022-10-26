
locals {
  raw_data     = jsondecode(data.http.region_cidr.response_body)
  myregion = [for exp in local.raw_data.regions : exp.region]
  mycidrs = [for exp in local.raw_data.regions : exp.cidrs]
  oci_cidr_region1 = [for exp in "${element(local.mycidrs, "${index(local.myregion, var.region1)}")}" : exp.cidr]
  oci_cidr_region2 = [for exp in "${element(local.mycidrs, "${index(local.myregion, var.region2)}")}" : exp.cidr]
}

output "out1" {
  value = local.oci_cidr_region1
}

output "out2" {
  value = local.oci_cidr_region2
}