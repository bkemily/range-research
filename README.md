# CIS4416 Proxmox VM Provisioning (Ansible)

This project automates creating and booting a single virtual machine from an OVF template in Proxmox VE using Ansible.  
It’s built for the **CNT4416 War Gaming** environment.

---

## Project Files
```
host_attack_scripts/
├── bash/
│   ├── create_account.sh
│   ├── create_account2.sh
│   ├── create_account3.sh
│   ├── cron_job.sh
│   ├── cron_job2.sh
│   ├── cron_job3.sh
│   ├── firewall.sh
│   ├── Manipulation.sh
│   ├── Manipulation2.sh
│   ├── masquerading.sh
│   ├── masquerading2.sh
│   ├── obfuscation.sh
│   └── obfuscation2.sh
└── powershell/
    ├── create_account.ps1
    ├── create_account2.ps1
    ├── firewall.ps1
    ├── manipulation.ps1
    ├── masquerading.ps1
    ├── obfuscation.ps1
    └── scheduled_task.ps1
inventory/
├── group_vars/
│   └── all.yml                           # Global variables for all stages
└── hosts.yml                             # Proxmox host inventory
network_attack_scripts/
├── bruteglasfishExploit.sh
├── nmapScript.sh
├── proftpdExploit.sh
├── psexecExploit.sh
└── smbExploit.sh
stage0/
├── stage0_configure_proxmox_network.yml  # Main Stage 0 playbook
└── README.md                             # Stage 0 Documentation
stage1/
├── stage1_bootstrap_security_onion.yml   # Main Stage 1 playbook
├── files/
│   ├── auto_runner.sh                    # Auto-runner script (future use)
│   ├── start_campaign.sh                 # Manual campaign script (future use)
│   └── auto-runner.service               # Systemd service (future use)
└── README.md                             # Stage 1 Documentation
stage2/
├── run_full_campaign.yml                 # Main Stage 2 playbook
├── deploy_infrastructure.yml             # Phase 2.1: VM deployment
├── configure_network.yml                 # Phase 2.2: Network config (in progress)
├── activate_attacks.yml                  # Phase 2.3: Attack activation (future use)
├── monitor_campaign.yml                  # Phase 2.4: Monitoring (future use)
├── collect_data.yml                      # Phase 2.5: Data collection (future use)
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
│   ├── attacks/                          # Placeholder for Phase 2.3: Attack activation
│   │   └── 
│   ├── monitoring/                       # Placeholder for Phase 2.4: Monitoring
│   │   └── 
│   └── data_collection/                  # Placeholder for Phase 2.5: Data collection
│       └── 
├── pfsense_configs/
│   ├── instructor-conf.xml.j2            # Instructor template
│   ├── student-group-XX.xml.j2           # Student template
│   └── generated/                        # Generated configs
│       ├── instructor.xml
│       ├── Group[1-N].xml                # Based on max_student_groups
└── README.md                             # Stage 2 Documentation
run_full_experiment.yml                   # Full experiment orchestrator
EXPERIMENT_EXECUTION_GUIDE.md             # Detailed execution guide
QUICK_REFERENCE.md                        # Quick commands reference
README.md                                 # Full Project Documentation
```
## Prerequisites

### On the control machine
Install Ansible and required collections:
    `sudo apt install ansible -y`
    `ansible-galaxy collection install community.general`

### On the Proxmox node
Ensure:
- VM templates exist in `/mnt/pve/ovfstore/`:
  - `pfsense-template.ovf`
  - `kali-template.ovf`
  - `metasploitable3-template.ovf`
  - `security-onion-template.ovf`
- Control machine can reach Proxmox on port 8006 (API) and 22 (SSH)
- User credentials (root@pam) have permission to manage VMs

## How to Run

### Full Experiment
```bash
ansible-playbook -i inventory/hosts.yml run_full_experiment.yml
```

### Individual Stages
```bash
# Stage 0: Configure network topology
ansible-playbook -i inventory/hosts.yml stage0/stage0_configure_proxmox_network.yml

# Stage 1: Deploy Security Onion monitoring
ansible-playbook -i inventory/hosts.yml stage1/stage1_bootstrap_security_onion.yml

# Stage 2: Deploy infrastructure (currently implemented)
ansible-playbook -i inventory/hosts.yml stage2/run_full_campaign.yml
```

## Notes & Current Behavior
### Stage 0: Network Topology Configuration
**Status:** Fully implemented and operational

Creates the foundational network infrastructure:
- Configures Proxmox network bridges (vmbr0.68, vmbr51, vmbr255000 series)
- Validates VM templates in `/mnt/pve/ovfstore/`
- Sets up VLAN tagging and network segmentation

### Stage 1: Security Onion Bootstrap
**Status:** Fully implemented and operational

Deploys centralized monitoring infrastructure:
- Provisions Security Onion VM from template
- Configures network interfaces for traffic monitoring
- Validates service health and Zeek workers
- Prepares for multi-group traffic capture

### Stage 2: Infrastructure Deployment (Phase 2.1)
**Status:** Partially implemented

#### Currently Working:
- **Instructor Group Deployment**
  - Deploys instructor pfSense VM
  - Assigns network bridges (WAN: vmbr255000, LAN: vmbr51)
  - Deploys instructor Kali Linux VM with vmbr51 connection
  
- **Student Group Deployment** (dynamic based on `max_student_groups`)
  - Deploys student pfSense VMs for each group (Group 1 through N)
  - Assigns hierarchical network bridges:
    - WAN: vmbr51 (connects to instructor pfSense)
    - LAN: vmbr255001, vmbr255002, ... vmbr25500N
  - Deploys student Kali Linux VMs (connected to group LAN bridges)
  - Deploys Metasploitable3 target VMs (connected to group LAN bridges)

#### In Progress:
- **Phase 2.2:** Network Configuration
  - Automated pfSense configuration via SSH

#### Pending Implementation:
- **Phase 2.3:** Attack Activation
  - Deploy attack scripts to Kali VMs
  - Configure attack orchestration and timing
  
- **Phase 2.4:** Campaign Monitoring
  - Real-time status checks
  
- **Phase 2.5:** Data Collection
  - PCAP and log retrieval from Security Onion
  - Dataset labeling and organization
  
- **Phase 2.6:** Teardown
  - Automated VM cleanup

Future stages will include:
- Campaign variation strategies
- Seeded randomization for reproducible datasets
- Multi-modal data collection (PCAP, Zeek logs, Suricata alerts)
- Automated labeling and metadata generation

## Known Issues & Workarounds

### pfSense Console Setup Wizard
**Issue:** pfSense VMs boot into initial setup wizard despite template pre-configuration  
**Impact:** Blocks automated SSH access and network configuration  
**Current Workaround:** Manual console interaction required to assign interfaces (vtnet0→WAN, vtnet1→LAN)  
**Future Solution:** Investigating pre-seed configuration methods or API-based initial setup

### Security Onion Interface Bonding
**Issue:** Bonded interfaces conflict with Zeek worker requirements  
**Resolution:** Use individual promiscuous mode interfaces instead of bonds
