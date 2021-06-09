provider "vsphere" {
  user           = var.vmc_vsphere_username
  password       = var.vmc_vsphere_password
  vsphere_server = var.vmc_vsphere_server
  allow_unverified_ssl = true
}

provider "nsxt" {
  host                 = var.vmc_nsx_server
  vmc_token            = var.vmc_nsx_token
  allow_unverified_ssl = true
  enforcement_point    = "vmc-enforcementpoint"
}