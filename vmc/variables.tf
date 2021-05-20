variable "avi_password" {}
variable "avi_username" {}
variable "vmc_vsphere_username" {}
variable "vmc_vsphere_password" {}
variable "vmc_vsphere_server" {}
variable "vmc_nsx_server" {}
variable "no_access_vcenter" {}
variable "vCenterIp" {}

variable "vmc_nsx_token" {
  sensitive = true
}
variable "vmc_org_id" {
  sensitive = true
}
variable "vmc_sddc_id" {
  sensitive = true
}
variable "my_public_ip" {}

variable "my_private_ip" {}

variable "EasyAviInSDDC" {}

variable "jump" {
  type = map
  default = {
    cpu = 2
    memory = 4096
    disk = 20
    public_key_path = "~/.ssh/id_rsa.pub"
    private_key_path = "~/.ssh/id_rsa"
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    aviSdkVersion = "18.2.9"
    username = "ubuntu"
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
  }
}

variable "ansible" {
  type = map
  default = {
    version = "2.9.12"
  }
}

variable "backend" {
  type = map
  default = {
    cpu = 2
    memory = 4096
    disk = 20
    wait_for_guest_net_routable = "false"
    template_name = "ubuntu-bionic-18.04-cloudimg-template"
    url_demovip_server = "https://github.com/tacobayle/demovip_server"
    username = "ubuntu"
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
  }
}