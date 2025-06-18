module "vm1" {
  source = "./modules/proxmox_vm"

  pm_api_token = var.pm_api_token
  pm_endpoint = var.pm_endpoint
  pm_vm_hostname  = "web-dev"
  pm_vm_user      = "user"
  domain          = "pve1.local"
  ssh_key         = ""
  ip_configs = [
    { address = "" },
    { address = "", gateway = "" }
  ]

  pm_vm_tags      = ["opentofu"]
  pm_template_tag = "template"
  pm_target_node  = "pve1"
  pm_cores        = 2
  pm_sockets      = 1
  pm_memory       = 2048
  pm_onboot       = true

  pm_disk = {
    storage = "local-lvm"
    size    = 20
  }

  additionnal_disks = []
}

module "vm2" {
  source = "./modules/proxmox_vm"

  pm_api_token = var.pm_api_token
  pm_endpoint = var.pm_endpoint
  pm_vm_hostname  = "web-prod"
  pm_vm_user      = "user"
  domain          = "pve1.local"
  ssh_key         = ""
  ip_configs = [
    { address = "" },
    { address = "", gateway = "" }
  ]

  pm_vm_tags      = ["opentofu"]
  pm_template_tag = "template"
  pm_target_node  = "pve1"
  pm_cores        = 2
  pm_sockets      = 1
  pm_memory       = 2048
  pm_onboot       = true

  pm_disk = {
    storage = "local-lvm"
    size    = 20
  }

  additionnal_disks = []
}