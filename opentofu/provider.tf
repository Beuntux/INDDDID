terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.78.1"
    }
  }
}

provider "proxmox" {
  # Configuration options
  endpoint = var.pm_endpoint
  api_token = var.pm_api_token
  insecure = true
  ssh {
    agent = true
    username = "root"
    node {
      name    = "pve1"
      address = ""
    }
  }
}