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
    time = {
      source = "hashicorp/time"
      version = "= 0.6.0"
    }
    null = {
      source = "hashicorp/null"
      version = "= 3.0.0"
    }
    vmc = {
      source = "terraform-providers/vmc"
      version = "= 1.5.1"
    }
  }
  required_version = ">= 0.13"
}