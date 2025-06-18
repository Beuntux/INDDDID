variable "pm_endpoint" {
  description = "Url API Proxmox"
  type = string
}

variable "pm_api_token" {
  description = "Token to connect Proxmox API"
  type = string
}




variable "pm_target_node" {
  description = "Proxmox node"
  type        = string
  default = "pve1"
}

variable "pm_onboot" {
  description = "Auto start VM when node is start"
  type        = bool
  default     = true
}

variable "target_node_domain" {
  description = "Proxmox node domain"
  type        = string
  default = ""
}

variable "pm_vm_hostname" {
  description = "VM hostname"
  type        = string
}

variable "domain" {
  description = "VM domain"
  type        = string
  default = "pve1.local"
}

variable "pm_vm_tags" {
  description = "VM tags"
  type        = list(string)
  default = [ "opentofu" ]
}

variable "pm_template_tag" {
  description = "Template tag"
  type        = string
  default = "template"
}

variable "pm_sockets" {
  description = "Number of sockets"
  type        = number
  default     = 1
}

variable "pm_cores" {
  description = "Number of cores"
  type        = number
  default     = 2
}

variable "pm_memory" {
  description = "Number of memory in MB"
  type        = number
  default     = 2048
}

variable "pm_vm_user" {
  description = "User"
  type        = string
  sensitive   = true
  default = "user"
}

variable "ssh_key" {
  type = string
}

variable "pm_disk" {
  description = "Disk (size in Gb)"
  type = object({
    storage = string
    size    = number
  })
  default = {
    storage = "local-lvm"
    size = 20
  }
}

variable "additionnal_disks" {
  description = "Additionnal disks"
  type = list(object({
    storage = string
    size    = number
  }))
  default = []
}

variable "ip_configs" {
  description = "List of IP configs (one per NIC)"
  type = list(object({
    address = string
    gateway = optional(string)
  }))
}