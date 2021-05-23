resource "null_resource" "se_creation" {
  provisioner "local-exec" {
    command = "export ANSIBLE_NOCOLOR=True; export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook ansible/pbSe.yml --extra-vars '{\"no_access_vcenter\": ${jsonencode(var.no_access_vcenter)}, \"vsphere_username\": ${jsonencode(var.vmc_vsphere_username)}, \"vsphere_password\": ${jsonencode(var.vmc_vsphere_password)}, \"vsphere_server\": ${var.vmc_vsphere_server}, \"avi_username\": ${var.avi_username}, \"avi_password\": ${var.avi_password}}'"
  }
}