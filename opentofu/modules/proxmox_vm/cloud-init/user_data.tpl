#cloud-config
hostname: ${pm_vm_hostname}
local-hostname: ${pm_vm_hostname}
fqdn: ${pm_vm_hostname}.${domain}
manage_etc_hosts: true
timezone: Europe/Paris
package_update: true
package_upgrade: true
users:
  - default
  - name: ${pm_vm_user}
    groups:
      - sudo
    shell: /bin/bash  
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${ssh_key}
ssh_pwauth: True ## This line enables ssh password authentication