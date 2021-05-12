resource "vsphere_content_library" "library" {
  name            = var.no_access_vcenter.cl_avi_name
  storage_backing = [data.vsphere_datastore.datastore.id]
}

resource "vsphere_content_library_item" "avi" {
  name        = "Avi OVA file"
  description = "Avi OVA file"
  library_id  = vsphere_content_library.library.id
  file_url = var.no_access_vcenter.aviOva
}

resource "vsphere_content_library_item" "ubuntu" {
  name        = "Ubuntu OVA file Jump"
  description = "Ubuntu OVA file Jump"
  library_id  = vsphere_content_library.library.id
  file_url = var.no_access_vcenter.ubuntuJump
}

resource "vsphere_content_library_item" "ubuntu_backend" {
  count = (var.no_access_vcenter.application == true ? 1 : 0)
  name        = "Ubuntu OVA file Backend"
  description = "Ubuntu OVA file Backend"
  library_id  = vsphere_content_library.library.id
  file_url = var.no_access_vcenter.ubuntuApp
}