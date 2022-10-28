provider "oci" {
  alias            = "r1"
  region           = var.region1
}

provider "oci" {
  alias            = "r2"
  region           = var.region2
}

provider "oci" {
  alias            = "r3"
  region           = var.region3
}
