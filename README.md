# CIS4416 Proxmox VM Provisioning (Ansible)

This project automates creating and booting a single virtual machine from an OVF template in Proxmox VE using Ansible.  
It’s built for the **CNT4416 War Gaming** environment.

---

## Project Files
```
host_attack_scripts/
├── stage0_configure_proxmox_network.yml   # Main playbook
└── README.md                              # Stage 0 Information
inventory/
├── stage0_configure_proxmox_network.yml   # Main playbook
└── README.md                              # Stage 0 Information
network_attack_scripts/
├── stage0_configure_proxmox_network.yml   # Main playbook
└── README.md                              # Stage 0 Information
stage0/
├── stage0_configure_proxmox_network.yml   # Main playbook
└── README.md                              # Stage 0 Information
stage1/
├── stage1_bootstrap_security_onion.yml   # Main playbook
├── files/
│   ├── auto_runner.sh                    # Auto-runner script (future use)
│   ├── start_campaign.sh                 # Manual campaign script (future use)
│   └── auto-runner.service               # Systemd service (future use)
└── README.md                             # Stage 1 Information
stage2/
├── run_full_campaign.yml                 # Master orchestrator
├── deploy_infrastructure.yml             # Phase 2.1: VM deployment
├── configure_network.yml                 # Phase 2.2: Network config
├── activate_attacks.yml                  # Phase 2.3: Attack activation
├── monitor_campaign.yml                  # Phase 2.4: Monitoring
├── collect_data.yml                      # Phase 2.5: Data collection
├── teardown.yml                          # Cleanup/destruction
├── generate_pfsense_configs.yml          # Generate XML configs
├── tasks/
│   ├── infrastructure/
│   │   ├── deploy_spark_pfsense.yml
│   │   ├── deploy_instructor_group.yml
│   │   ├── deploy_instructor_pfsense.yml
│   │   ├── deploy_instructor_kali.yml
│   │   ├── deploy_student_group.yml
│   │   ├── deploy_student_pfsense.yml
│   │   ├── deploy_student_kali_vms.yml
│   │   └── deploy_student_ms3_vms.yml
│   ├── network/
│   │   └── configure_pfsense.yml
│   │   └── generate_pfsense_configs.yml
│   ├── attacks/
│   │   └── 
│   ├── monitoring/
│   │   └── 
│   └── data_collection/
│       └── 
├── pfsense_configs/
│   ├── instructor-conf.xml.j2            # Instructor template
│   ├── student-group-XX.xml.j2           # Student template
│   └── generated/                        # Generated configs
│       ├── instructor.xml
│       ├── Group1.xml
│       ├── Group2.xml
│       └── ... (Group3-15.xml)
└── README.md                             # Stage 2 Information

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
