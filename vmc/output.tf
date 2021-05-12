# Outputs for Terraform

output "controllers_public" {
  value = vmc_public_ip.public_ip_controller.*.ip
}

output "controllers_private" {
  value = vsphere_virtual_machine.controller.*.default_ip_address
}

output "httpVsPublicIP" {
  value = vmc_public_ip.public_ip_vsHttp.*.ip
}

output "httpVsPrivateIP" {
  value = var.no_access_vcenter.application ? [var.no_access_vcenter.network_vip.ipStartPool] : null
}

output "dnsVsPublicIP" {
  value = vmc_public_ip.public_ip_vsDns.*.ip
}

output "dnsVsPrivateIP" {
  value = var.no_access_vcenter.application ? [var.no_access_vcenter.network_vip.ipEndPool] : null
}

output "aviUsername" {
  value = var.avi_username
}

output "aviPassword" {
  value = var.avi_password
}