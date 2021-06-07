resource "nsxt_policy_group" "se" {
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
}

resource "null_resource" "se_exclusion_list" {
  provisioner "local-exec" {
    command = "python3 python/pyVMC2.py ${var.vmc_nsx_token} ${var.vmc_org_id} ${var.vmc_sddc_id} append-exclude-list ${nsxt_policy_group.se.path}"
  }
}