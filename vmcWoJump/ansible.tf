resource "null_resource" "wait_https_controllers" {
  depends_on = [vsphere_virtual_machine.controller]
  count = (var.no_access_vcenter.controller.cluster == true ? 3 : 1)

  provisioner "local-exec" {
    command = "count=1 ; until $(curl --output /dev/null --silent --head -k https://${vsphere_virtual_machine.controller[count.index].default_ip_address}); do echo \"Attempt $count: Waiting for Avi Controllers to be ready...\"; sleep 5 ; count=$((count+1)) ;  if [ \"$count\" = 120 ]; then echo \"ERROR: Unable to connect to Avi Controller API\" ; exit 1 ; fi ; done"
  }
}

resource "null_resource" "ansible_avi_cluster_1" {
  depends_on = [null_resource.wait_https_controllers]

  provisioner "local-exec" {
    command = "cd ansible ; export ANSIBLE_NOCOLOR=True ; /home/ubuntu/.local/bin/ansible-playbook pbInitCluster.yml --extra-vars '{\"avi_version\": ${jsonencode(split(".ova", split("-", basename(var.no_access_vcenter.aviOva))[1])[0])}, \"controllerPrivateIps\": ${jsonencode(vsphere_virtual_machine.controller.*.default_ip_address)}, \"controller\": ${jsonencode(var.no_access_vcenter.controller)}, \"controllerFloatingIp\": ${jsonencode(var.no_access_vcenter.network_management.avi_ctrl_floating_ip)}, \"controllerDefaultGateway\": ${jsonencode(var.no_access_vcenter.network_management.defaultGateway)}, \"avi_username\": ${jsonencode(var.avi_username)}, \"avi_password\": ${jsonencode(var.avi_password)}}'"
  }
}

resource "null_resource" "ansible_avi_cluster_2" {
  depends_on = [null_resource.ansible_avi_cluster_1]
  count = (var.no_access_vcenter.controller.cluster == true ? 3 : 1)

  provisioner "local-exec" {
    command = "count=1 ; until $(curl --output /dev/null --silent --head -k https://${vsphere_virtual_machine.controller[count.index].default_ip_address}); do echo \"Attempt $count: Waiting for Avi Controllers to be ready...\"; sleep 5 ; count=$((count+1)) ;  if [ \"$count\" = 120 ]; then echo \"ERROR: Unable to connect to Avi Controller API\" ; exit 1 ; fi ; done"
  }
}

resource "null_resource" "ansible_avi_cluster_3" {
  depends_on = [null_resource.ansible_avi_cluster_2]

  provisioner "local-exec" {
    command = "export ANSIBLE_NOCOLOR=True ; ansible-playbook ansible/pbClusterConfig.yml --extra-vars '{\"no_access_vcenter\": ${jsonencode(var.no_access_vcenter)}, \"avi_version\": ${jsonencode(split(".ova", split("-", basename(var.no_access_vcenter.aviOva))[1])[0])}, \"controllerPrivateIps\": ${jsonencode(vsphere_virtual_machine.controller.*.default_ip_address)}, \"controller\": ${jsonencode(var.no_access_vcenter.controller)}, \"controllerFloatingIp\": ${jsonencode(var.no_access_vcenter.network_management.avi_ctrl_floating_ip)}, \"controllerDefaultGateway\": ${jsonencode(var.no_access_vcenter.network_management.defaultGateway)}, \"avi_username\": ${jsonencode(var.avi_username)}, \"avi_password\": ${jsonencode(var.avi_password)}}'"
  }

}


resource "null_resource" "ansible_avi_cloud" {
  depends_on = [null_resource.ansible_avi_cluster_3]

  provisioner "local-exec" {
    command = "export ANSIBLE_NOCOLOR=True ; ansible-playbook ansible/pbCloudOnly.yml --extra-vars '{\"vsphere_server\": ${jsonencode(var.vmc_vsphere_server)}, \"avi_version\": ${jsonencode(split(".ova", split("-", basename(var.no_access_vcenter.aviOva))[1])[0])}, \"controllerPrivateIps\": ${jsonencode(vsphere_virtual_machine.controller.*.default_ip_address)}, \"vsphere_password\": ${jsonencode(var.vmc_vsphere_password)}, \"controller\": ${jsonencode(var.no_access_vcenter.controller)}, \"vsphere_username\": ${jsonencode(var.vmc_vsphere_username)}, \"no_access_vcenter\": ${jsonencode(var.no_access_vcenter)}, \"avi_username\": ${jsonencode(var.avi_username)}, \"avi_password\": ${jsonencode(var.avi_password)}}'"
  }

}

resource "null_resource" "ansible_avi_se" {
  depends_on = [null_resource.ansible_avi_cloud]

  provisioner "local-exec" {
    command = "export ANSIBLE_NOCOLOR=True ; export ANSIBLE_HOST_KEY_CHECKING=False; ansible/ansible-playbook pbSe.yml --extra-vars '{\"vsphere_server\": ${jsonencode(var.vmc_vsphere_server)}, \"avi_version\": ${jsonencode(split(".ova", split("-", basename(var.no_access_vcenter.aviOva))[1])[0])}, \"controllerPrivateIps\": ${jsonencode(vsphere_virtual_machine.controller.*.default_ip_address)}, \"vsphere_password\": ${jsonencode(var.vmc_vsphere_password)}, \"controller\": ${jsonencode(var.no_access_vcenter.controller)}, \"vsphere_username\": ${jsonencode(var.vmc_vsphere_username)}, \"no_access_vcenter\": ${jsonencode(var.no_access_vcenter)}, \"avi_username\": ${jsonencode(var.avi_username)}, \"avi_password\": ${jsonencode(var.avi_password)}}'"
  }

}

resource "null_resource" "ansible_avi_vs" {
  depends_on = [null_resource.ansible_avi_se]

  provisioner "local-exec" {
    command = "export ANSIBLE_NOCOLOR=True ; ansible-playbook ansible/pbVsOnly.yml --extra-vars '{\"vsphere_server\": ${jsonencode(var.vmc_vsphere_server)}, \"avi_version\": ${jsonencode(split(".ova", split("-", basename(var.no_access_vcenter.aviOva))[1])[0])}, \"controllerPrivateIps\": ${jsonencode(vsphere_virtual_machine.controller.*.default_ip_address)}, \"vsphere_password\": ${jsonencode(var.vmc_vsphere_password)}, \"controller\": ${jsonencode(var.no_access_vcenter.controller)}, \"vsphere_username\": ${jsonencode(var.vmc_vsphere_username)}, \"no_access_vcenter\": ${jsonencode(var.no_access_vcenter)}, \"avi_username\": ${jsonencode(var.avi_username)}, \"avi_password\": ${jsonencode(var.avi_password)}, \"avi_backend_servers_no_access_vcenter\": ${jsonencode(vsphere_virtual_machine.backend.*.guest_ip_addresses)}}'"
  }
}