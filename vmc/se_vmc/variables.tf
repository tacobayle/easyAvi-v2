variable "avi_password" {}
variable "avi_username" {}
variable "avi_tenant" {}
variable "vmc_vsphere_username" {}
variable "vmc_vsphere_password" {}
variable "vmc_vsphere_server" {}
variable "no_access_vcenter" {}
variable "vmc_sddc_id" {}
variable "vmc_org_id" {}
variable "vmc_nsx_token" {
  sensitive = true
}
variable "vmc_nsx_server" {}
