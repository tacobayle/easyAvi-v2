data "nsxt_policy_transport_zone" "tzMgmt" {
  display_name = "vmc-overlay-tz"
}

resource "nsxt_policy_nat_rule" "dnat_vsHttp" {
  count = (var.no_access_vcenter.public_ip == true ? 1 : 0)
  display_name         = "EasyAvi-dnat-VS-HTTP"
  action               = "DNAT"
  source_networks      = []
  destination_networks = [vmc_public_ip.public_ip_vsHttp[count.index].ip]
  translated_networks  = [var.no_access_vcenter.network_vip.ipStartPool]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}

resource "nsxt_policy_nat_rule" "dnat_vsDns" {
  depends_on = [nsxt_policy_nat_rule.dnat_vsHttp]
  count = (var.no_access_vcenter.public_ip == true ? 1 : 0)
  display_name         = "EasyAvi-dnat-VS-DNS"
  action               = "DNAT"
  source_networks      = []
  destination_networks = [vmc_public_ip.public_ip_vsDns[count.index].ip]
  translated_networks  = ["${split(".", var.no_access_vcenter.network_vip.ipStartPool)[0]}.${split(".", var.no_access_vcenter.network_vip.ipStartPool)[1]}.${split(".", var.no_access_vcenter.network_vip.ipStartPool)[2]}.${split(".", var.no_access_vcenter.network_vip.ipStartPool)[3] + 1}"]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}

resource "nsxt_policy_group" "se" {
  count = (var.no_access_vcenter.nsxt_exclusion_list == true ? 1 : 0)
  display_name = var.no_access_vcenter.EasyAviSeExclusionList
  domain       = "cgw"
  description  = var.no_access_vcenter.EasyAviSeExclusionList

  criteria {
    condition {
      member_type = "VirtualMachine"
      key = "Name"
      operator = "STARTSWITH"
      value = "EasyAvi-"
    }
  }

  conjunction {
    operator = "OR"
  }

  criteria {
    condition {
      member_type = "VirtualMachine"
      key = "Name"
      operator = "STARTSWITH"
      value = "${split(".ova", basename(var.no_access_vcenter.aviOva))[0]}-"
    }
  }
}

resource "null_resource" "se_exclusion_list" {
  count = (var.no_access_vcenter.nsxt_exclusion_list == true ? 1 : 0)
  provisioner "local-exec" {
    command = "python3 python/pyVMC2.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} append-exclude-list ${nsxt_policy_group.se[count.index].path}"
  }
}

resource "nsxt_policy_group" "vsHttp" {
  count = (var.no_access_vcenter.dfw_rules == true ? 1 : 0)
  display_name = "EasyAvi-VS-HTTP"
  domain       = "cgw"
  description  = "EasyAvi-VS-HTTP"
  criteria {
    ipaddress_expression {
      ip_addresses = [vmc_public_ip.public_ip_vsHttp[count.index].ip, var.no_access_vcenter.network_vip.ipStartPool]
    }
  }
}

resource "nsxt_policy_group" "vsDns" {
  count = (var.no_access_vcenter.dfw_rules == true ? 1 : 0)
  depends_on = [nsxt_policy_group.vsHttp]
  display_name = "EasyAvi-VS-DNS"
  domain       = "cgw"
  description  = "EasyAvi-VS-DNS"
  criteria {
    ipaddress_expression {
      ip_addresses = [vmc_public_ip.public_ip_vsDns[count.index].ip, "${split(".", var.no_access_vcenter.network_vip.ipStartPool)[0]}.${split(".", var.no_access_vcenter.network_vip.ipStartPool)[1]}.${split(".", var.no_access_vcenter.network_vip.ipStartPool)[2]}.${split(".", var.no_access_vcenter.network_vip.ipStartPool)[3] + 1}"]
    }
  }
}

resource "null_resource" "cgw_vsHttp_create" {
  count = (var.no_access_vcenter.dfw_rules == true ? 1 : 0)
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} new-cgw-rule easyavi_inbound_vsHttp any ${nsxt_policy_group.vsHttp[count.index].id} HTTP ALLOW public 0"
  }
}

resource "null_resource" "cgw_vsHttps_create" {
  count = (var.no_access_vcenter.dfw_rules == true ? 1 : 0)
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} new-cgw-rule easyavi_inbound_vsHttps any ${nsxt_policy_group.vsHttp[count.index].id} HTTPS ALLOW public 0"
  }
}

resource "null_resource" "cgw_vsDns_create" {
  count = (var.no_access_vcenter.dfw_rules == true ? 1 : 0)
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} new-cgw-rule easyavi_inbound_vsDns any ${nsxt_policy_group.vsDns[count.index].id} DNS ALLOW public 0"
  }
}

resource "null_resource" "cgw_controller_https_create" {
  count = (var.no_access_vcenter.controller.public_ip == true ? 1 : 0)
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} new-cgw-rule easyavi_inbound_avi_controller any ${nsxt_policy_group.controller[count.index].id} HTTPS ALLOW public 0"
  }
}

resource "nsxt_policy_nat_rule" "dnat_controller_admin" {
  count = (var.EasyAviInSDDC == true ? 0 : 1)
  display_name         = "EasyAvi-dnat-controller-admin"
  action               = "DNAT"
  source_networks      = []
  destination_networks = [vmc_public_ip.public_ip_controller[0].ip]
  translated_networks  = [vsphere_virtual_machine.controller[0].default_ip_address]
  gateway_path         = "/infra/tier-1s/cgw"
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"
}

resource "nsxt_policy_group" "easyavi_appliance" {
  count = (var.EasyAviInSDDC == true ? 0 : 1)
  display_name = "EasyAvi-Appliance"
  domain       = "cgw"
  description  = "EasyAvi-Appliance"
  criteria {
    ipaddress_expression {
      ip_addresses = [var.my_public_ip, var.my_private_ip]
    }
  }
}

resource "nsxt_policy_group" "controller_admin" {
  count = (var.EasyAviInSDDC == true ? 0 : 1)
  display_name = "controller_admin"
  domain       = "cgw"
  description  = "controller_admin"
  criteria {
    ipaddress_expression {
      ip_addresses = [vsphere_virtual_machine.controller[0].default_ip_address, vmc_public_ip.public_ip_controller_admin[0].ip]
    }
  }
}

resource "null_resource" "cgw_controller_admin_https" {
  count = (var.EasyAviInSDDC == true ? 0 : 1)
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} new-cgw-rule easyavi_inbound_controller_admin_https ${nsxt_policy_group.easyavi_appliance[0].id} ${nsxt_policy_group.controller_admin[0].id} HTTPS ALLOW public 0"
  }
}

resource "null_resource" "cgw_controller_admin_ssh" {
  count = (var.EasyAviInSDDC == true ? 0 : 1)
  provisioner "local-exec" {
    command = "python3 python/pyVMC.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} new-cgw-rule easyavi_inbound_controller_admin_ssh ${nsxt_policy_group.easyavi_appliance[0].id} ${nsxt_policy_group.controller_admin[0].id} SSH ALLOW public 0"
  }
}