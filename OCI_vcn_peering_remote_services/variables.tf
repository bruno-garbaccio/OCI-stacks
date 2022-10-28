variable "tenancy_ocid" {}
variable "r1_compartment_ocid" {}
variable "r2_compartment_ocid" {}
variable "r2_name_vcn" {}
variable "r1_name_vcn" {}
variable "region" {}
variable "region1" {}
variable "region2" {}
variable "authorized_ips" {}
variable "r1_cidr_vcn" {}
variable "r1_cidr_pubnet" {}
variable "r1_cidr_privnet" {}
variable "r2_cidr_vcn" {}
variable "r2_cidr_pubnet" {}
variable "r2_cidr_privnet" {}
variable "is_region3" {}
variable "r3_compartment_ocid" {default = ""}
variable "r3_name_vcn" {default = "vcn3"}
variable "region3" {default = "us-phoenix-1"}
variable "r3_cidr_vcn" {default = "192.168.0.0/16"}
variable "r3_cidr_pubnet" {default = "192.168.0.0/24"}
variable "r3_cidr_privnet" {default = "192.168.2.0/24"}



