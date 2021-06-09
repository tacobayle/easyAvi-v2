resource "vsphere_tag_category" "EasyAvi" {
  name = var.no_access_vcenter.EasyAviTagCategoryName
  cardinality = "MULTIPLE"
  associable_types = [
    "VirtualMachine",
  ]
}

resource "vsphere_tag" "EasyAvi" {
  name             = var.no_access_vcenter.deployment_id
  category_id      = vsphere_tag_category.EasyAvi.id
}