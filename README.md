# CIS4416 Proxmox VM Provisioning (Ansible)

This project automates creating and booting a single virtual machine from an OVF template in Proxmox VE using Ansible.  
It’s built for the **CNT4416 War Gaming** environment.

---

## Project Files


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
```bash
ansible-playbook -i inventory.yml run_full_experiment.yml
```

## Notes & Current Behavior
