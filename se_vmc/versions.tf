terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
      version = "= 3.1.1"
    }
    vsphere = {
      source = "hashicorp/vsphere"
      version = "= 1.24.3"
    }
    null = {
      source = "hashicorp/null"
      version = "= 3.0.0"
    }
  }
  required_version = ">= 0.13"
}