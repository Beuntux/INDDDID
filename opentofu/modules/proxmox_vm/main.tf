data "proxmox_virtual_environment_vms" "template" {
  node_name = var.pm_target_node
  tags      = ["cloud-init", var.pm_template_tag]
}

resource "proxmox_virtual_environment_file" "cloud_user_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.pm_target_node

  source_raw {
    data = templatefile("${path.module}/cloud-init/user_data.tpl", {
      pm_vm_hostname = var.pm_vm_hostname
      domain         = var.domain
      pm_vm_user     = var.pm_vm_user
      ssh_key        = var.ssh_key
    })

    file_name = "${var.pm_vm_hostname}-ci-user.yml"
  }
}

resource "proxmox_virtual_environment_file" "cloud_meta_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.pm_target_node

  source_raw {
    data = file("${path.module}/cloud-init/meta_data.tpl")

    file_name = "${var.pm_vm_hostname}-ci-meta_data.yml"
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.pm_vm_hostname
  node_name = var.pm_target_node
  on_boot = var.pm_onboot


  agent {
    enabled = true
  }

  tags = var.pm_vm_tags

  cpu {
    type    = "x86-64-v2-AES"
    cores   = var.pm_cores
    sockets = var.pm_sockets
    flags   = []
  }

  memory {
    dedicated = var.pm_memory
  }

  network_device {
    bridge  = "vmbr0"
    model   = "virtio"
  }

  network_device {
    bridge  = "vmbr1"
    model   = "virtio"
  }

  # Ignore changes to the network
  ## MAC address is generated on every apply, causing
  ## TF to think this needs to be rebuilt on every apply
  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }

  boot_order    = ["scsi0"]
  scsi_hardware = "virtio-scsi-single"

  disk {
    interface    = "scsi0"
    iothread     = true
    datastore_id = "${var.pm_disk.storage}"
    size         = var.pm_disk.size
    discard      = "ignore"
  }

  dynamic "disk" {
    for_each = var.additionnal_disks
    content {
      interface    = "scsi${1 + disk.key}"
      iothread     = true
      datastore_id = "${disk.value.storage}"
      size         = disk.value.size
      discard      = "ignore"
      file_format  = "raw"
    }
  }

  clone {
    vm_id = data.proxmox_virtual_environment_vms.template.vms[0].vm_id
  }

  initialization {
    dynamic "ip_config" {
      for_each = var.ip_configs
      content {
        ipv4 {
          address = ip_config.value.address
          gateway = lookup(ip_config.value, "gateway", null)
        }
      }
    }

    datastore_id         = "local-lvm"
    interface            = "ide2"
    user_data_file_id    = proxmox_virtual_environment_file.cloud_user_config.id
    meta_data_file_id    = proxmox_virtual_environment_file.cloud_meta_config.id
  }
}