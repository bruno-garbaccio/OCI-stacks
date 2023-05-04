variable "region" {}
variable "tenancy_ocid" {} 
variable "targetCompartment" {} 
variable "ssh_key" { }
variable "use_custom_name" { default = false }
variable "jupyter_name" { default = "" }
variable "jupyter_ad" {}
variable "jupyter_shape" { default = "VM.GPU.A10.1" }
variable "jupyter_boot_volume_size" {}
variable "unsupported_jupyter_image" { default = "" } 
variable "vcn_compartment" { default = ""}
variable "vcn_id" { default = ""}
variable "use_existing_vcn" { default = false}
variable "public_subnet_id" { default = ""}
variable "private_subnet_id" { default = ""}
variable "vcn_subnet" { default = "172.16.0.0/21" }
variable "public_subnet" { default = "172.16.0.0/24" }


variable "private_subnet" { default = "172.16.4.0/22" }
variable "ssh_cidr" { default = "0.0.0.0/0" }

variable "jupyter_ocpus" { default = 2} 
variable "jupyter_ocpus_denseIO_flex" { default = 8} 
variable "jupyter_memory" { default = 16 }
variable "jupyter_custom_memory" { default = false }





variable "jupyter_block_volume_performance" { 
/* 
  Allowed values 
  "0.  Lower performance"
  "10. Balanced performance"
  "20. High Performance"
*/ 

default = "10. Balanced performance" 

}

variable "jupyter_block" { 
  default = false
} 

variable "jupyter_block_volume_size" { 
  default = 1000
}



variable "inst_prin" { default = true}
variable "api_user_key" { default = ""}
variable "api_fingerprint" { default = ""}
variable "api_user_ocid" { default = ""} 
variable "configure" { default = true }





variable "jupyter_username" { 
  type = string 
  default = "opc" 
} 


variable "private_deployment" { default = false }


  