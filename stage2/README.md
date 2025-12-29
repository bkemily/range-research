# Stage 2: Campaign Orchestration & Execution

## Overview

Stage 2 orchestrates complete cyber range campaigns by deploying infrastructure, configuring networks, activating attacks, monitoring execution, and collecting data. This is the primary automation for running reproducible cybersecurity training scenarios and generating labeled datasets for threat detection research.

## Purpose

- Deploy all virtual machines for a complete campaign
- Configure pfSense routing and firewall rules
- Activate attack campaigns across student groups
- Monitor campaign execution and system health
- Collect network traffic and log data
- Generate reproducible, labeled datasets

## Prerequisites

- Stage 0 completed (Proxmox network bridges configured)
- Stage 1 completed (Security Onion deployed and configured)
- pfSense templates configured with pre-loaded XML configs
- Kali, MS3 Ubuntu, and MS3 Windows OVF templates available
- SSH access to Proxmox and Security Onion
- Ansible 2.9+ installed on Security Onion

## Architecture

### Infrastructure VMs
| VM ID | Name | Purpose |
|-------|------|---------|
| 50 | Spark pfSense | Internet gateway |
| 100 | Instructor pfSense | Multi-group router |
| 101 | Instructor Kali | Instructor workstation |

### Student Group VMs (per group, repeated 1-15 times)
| VM ID Pattern | Name | Purpose |
|---------------|------|---------|
| X01 | Group pfSense | Group router |
| X02 | Kali 1 | Attack platform |
| X03 | Kali 2 | Attack platform |
| X04 | MS3 Ubuntu | Vulnerable target |
| X05 | MS3 Windows | Vulnerable target |

VM ID Calculation:
- Base ID = 200 + (group_number - 1) × 100
- Example: Group 1 = 201-205, Group 2 = 301-305, Group 15 = 1501-1505

### IP Addressing Scheme

#### Instructor Network (143.88.255.0/24):
- Instructor pfSense LAN: 143.88.255.1
- Instructor Kali: 143.88.255.10
- Security Onion: 143.88.255.9

#### Student Group X Networks:
- WAN: 143.88.0.(X×4-2)/30
  - Gateway (Instructor OPT): 143.88.0.(X×4-3)
  - Student pfSense WAN: 143.88.0.(X×4-2)
- LAN (/24): 143.88.X.0/24
  - pfSense LAN: 143.88.X.1
  - Kali 1: 143.88.X.10
  - Kali 2: 143.88.X.11
  - MS3 Ubuntu: 143.88.X.13
  - MS3 Windows: 143.88.X.14

## Files

```
stage2/
├── run_full_campaign.yml              # Master orchestrator
├── deploy_infrastructure.yml          # Phase 2.1: VM deployment
├── configure_network.yml              # Phase 2.2: Network config
├── activate_attacks.yml               # Phase 2.3: Attack activation
├── monitor_campaign.yml               # Phase 2.4: Monitoring
├── collect_data.yml                   # Phase 2.5: Data collection
├── teardown.yml                       # Cleanup/destruction
├── generate_pfsense_configs.yml       # Generate XML configs
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
│   ├── instructor-conf.xml.j2         # Instructor template
│   ├── student-group-XX.xml.j2        # Student template
│   └── generated/                     # Generated configs
│       ├── instructor.xml
│       ├── Group1.xml
│       ├── Group2.xml
│       └── ... (Group3-15.xml)
└── README.md                          # This file
```

## Campaign Phases

### Phase 2.1: Deploy Infrastructure
1. Validates prerequisites (SSH, templates, no VM conflicts)
2. Deploys Spark pfSense
3. Deploys Instructor infrastructure (pfSense, Kali)
4. Deploys Student groups (loops 1-max_student_groups)
5. Waits for VMs to boot (pfSense only - clients wait for config)
6. Verifies pfSense VMs are running

### Phase 2.2: Configure Network
1. Configures Instructor pfSense (runs pre-loaded XML via config.sh)
2. Configures Student pfSense instances (sequential, one at a time)
3. Waits for pfSense reboots and network convergence
4. Starts all client VMs (Kali, MS3) after network is ready
5. Verifies network connectivity

### Phase 2.3: Activate Attacks
1. 
2. 
3. 
4. Monitors attack execution status

### Phase 2.4: Monitor Campaign
1. 
2. 
3. 
4. 

### Phase 2.5: Collect Data
1. 
2. 
3. 
4. 
5. 
6. 

## Usage

### Run a Complete Campaign

```bash
cd /mnt/ovfstore/cyber-range-automation
ansible-playbook -i inventory/hosts.yml stage2/run_full_campaign.yml --ask-vault-pass
```

### Run Individual Phases

Deploy infrastructure only:

```bash
ansible-playbook -i inventory/hosts.yml stage2/deploy_infrastructure.yml --ask-vault-pass
```

Configure network only (requires infrastructure deployed):

```bash
ansible-playbook -i inventory/hosts.yml stage2/configure_network.yml --ask-vault-pass
```

### Teardown Campaign

Destroy all VMs and clean up:

```bash
ansible-playbook -i inventory/hosts.yml stage2/teardown.yml --ask-vault-pass
```

## Verification

### Check Deployed VMs

```bash
# On Proxmox
ssh root@192.168.68.89
qm list | grep -E "151|152|101|201|202|203|204|205"
```

Expected output for 1 group:
```
151  instructor-pfsense          running
152  instructor-kali             running
201  student-group01-pfsense     running
202  student-group01-kali1       running
203  student-group01-kali2       running
204  student-group01-ms3-ubuntu  running
205  student-group01-ms3-windows running
```

### Verify Network Configuration

```bash
# Check pfSense is configured
ssh admin@143.88.1.1
# Should show configured IPs, not wizard

# Check Instructor pfSense
ssh admin@143.88.255.1

# Check Student Group 1 pfSense (after config)
ssh admin@143.88.0.2
```

### Verify DHCP Assignments

```bash
# From Instructor Kali
ssh kali@143.88.255.10
ip addr show  # Should have 143.88.255.10

# From Student Group 1 Kali
ssh kali@143.88.1.10
ip addr show  # Should have 143.88.1.10
```


## Safety Features

- **Pre-deployment validation**: Checks for VM conflicts before starting
- **Template-based deployment**: Fast, consistent VM creation
- **Sequential pfSense configuration**: Avoids IP conflicts
- **Automatic network convergence**: Waits for routing to stabilize
- **Health monitoring**: Detects failed VMs during campaign
- **Graceful teardown**: Stops VMs before destroying them
- **Idempotent phases**: Safe to re-run individual phases
- **Template preservation**: Teardown excludes template VMs

## Output Data Structure

After campaign completion, data is organized as:

```
```

Campaign metadata includes:
- campaign_id
- start_time, end_time
- duration_hours
- max_student_groups
- vm_inventory


## Verification Checklist

After campaign completion:

- [ ] All VMs deployed and running
- [ ] pfSense configurations applied (check IPs)
- [ ] Client VMs have DHCP addresses
- [ ] Network connectivity works (ping tests)
- [ ] Attacks are running (check processes)
- [ ] Security Onion capturing traffic
- [ ] Zeek logs being generated
- [ ] Suricata alerts being recorded
- [ ] Campaign metadata recorded
- [ ] Data collection successful

## Next Steps

After Stage 2 completes:

1. **Analyze collected data** using Security Onion dashboards
2. **Export datasets** for machine learning model training
3. **Run additional campaigns** with different parameters