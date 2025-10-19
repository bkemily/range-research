# CIS4416 Proxmox VM Provisioning (Ansible)

This project automates creating and booting a single virtual machine from an OVF template in Proxmox VE using Ansible.  
It’s built for the **CIS4416 War Gaming** environment.

---

## Project Files

### `inventory.ini`
Defines the Proxmox VE node(s) and global connection variables used by Ansible.

### `deploy_one_vm.yml`
This playbook automates:
- Detecting `.ovf` template files stored in `/mnt/pve/ovfstore` on your Proxmox node  
- Selecting the first available OVF  
- Importing it to storage (`qm importovf`)  
- Setting up:
  - SeaBIOS boot mode  
  - virtio-scsi controller  
  - e1000 network interface on the correct bridge (`vmbr80` or `vmbr70`)  
  - Automatically derived VM name like `CIS4416 Kali 01`
- Starting the VM

## Prerequisites

### On the control machine
Install Ansible and required collections:
    `sudo apt install ansible -y`
    `ansible-galaxy collection install community.general`

### On the Proxmox node
Ensure:
- /mnt/pve/ovfstore/ exists and contains one or more .ovf template files.
- The control machine can reach Proxmox on port 8006 (for API) and 22 (for SSH).
- The user (root@pam) has permission to manage VMs.

## How to Run

### 1. Test connection to the Proxmox node
`ansible -i inventory.ini pve -m ping`
- Should see pong if Ansible can connect successfully.

### 2. Run the playbook
Run the playbook using the inventory file:
- `ansible-playbook -i inventory.ini deploy_one_vm.yml`

This will:
- Use the first .ovf template in /mnt/pve/ovfstore
- Create a VM with SeaBIOS
- Place it on vmbr80 (Group 1 default; can manually set group number by appending "-e lab_group=GX")
- Name it automatically (e.g., CIS4416 Kali 01)

## Notes & Current Behavior

**Boot Mode:** Uses SeaBIOS (legacy) for all VMs.  
**VM Naming:** Derived automatically from the OVF filename.

- **Example:** `TEMPLATE-kali-20241124-Experiment.ovf` → `CIS4416 Kali 01`

**Bridge Assignment:**
- Group 1 → `vmbr80`
- Group 2 → `vmbr90`

**VMID Scheme:**
- Group 1 → starts at `8001`
- Group 2 → starts at `9001`

Only the first OVF found in the directory is used  
(this will be changed later by editing `ovf_index` in the playbook).
