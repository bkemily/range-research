# Stage 0: Proxmox Network Configuration

## Overview

Stage 0 configures the Proxmox VE network infrastructure by creating all required bridge interfaces. This is a **one-time setup** that must be completed before deploying any VMs.

## Purpose

- Create Linux bridge interfaces for network isolation
- Configure bridges for instructor and student groups
- Establish network topology for Cyber War Gaming class
- Ensure safe rollback through automatic timestamped backups
- Prepare Proxmox for Security Onion deployment

## Prerequisites

- Ubuntu VM with Proxmox VE installed
- SSH/sudo access to Proxmox host
- Ansible 2.9+ installed on Ubuntu VM
- Network connectivity to Proxmox management interface

## Network Bridges Created

### Infrastructure Bridges
- **vmbr0**: Management bridge (VLAN-aware, existing)
- **vmbr0.68**: Management VLAN interface (192.168.68.89/24) (existing)
- **vmbr51**: Spark pfSense WAN (internet gateway)
- **vmbr10255**: Instructor LAN (143.88.255.0/24)

### Student Group Bridges (per group)
For each student group (1-N):
- **vmbr15XXX**: Student WAN bridge (connects to instructor pfSense)
  - Example: vmbr15001 (Group 1), vmbr15002 (Group 2)
- **vmbr10XXX**: Student LAN bridge (internal group network)
  - Example: vmbr10001 (Group 1), vmbr10002 (Group 2)

## Bridge Naming Schema (Exact as Implemented)

### **Infrastructure Bridges**
| Bridge | Purpose |
|--------|---------|
| `vmbr0` | Proxmox management bridge (VLAN-aware) |
| `vmbr0.68` | Management VLAN (192.168.68.89/24) |
| `vmbr50` | Internet (Spark WAN) |
| `vmbr51` | Closed network (VLAN-aware) |

### **Instructor Bridges**
| Bridge | Purpose |
|--------|---------|
| `vmbr255000` | Instructor LAN (143.88.255.0/24) |

### **Student Group Bridges** (max_student_groups)
The playbook dynamically generates these:

| Purpose | Format | Example (Group 1) |
|---------|--------|-------------------|
| Group WAN | `vmbr255GGG` | `vmbr255001` |
| Group LAN | `vmbrGGG000` | `vmbr001000` |

## Files

```
stage0/
├── stage0_configure_proxmox_network.yml   # Main playbook
└── README.md                              # This file
```

## What the Playbook Actually Does

1. Displays stage information and bridge plan  
2. Tests SSH connectivity to Proxmox  
3. Creates timestamped backup of `/etc/network/interfaces`  
4. Generates a full replacement configuration including all bridges  
5. Writes config to `/tmp/interfaces.new` locally  
6. Transfers it to Proxmox with SCP  
7. **Skips dry-run validation** (Proxmox doesn’t support `ifreload -i`)  
8. Applies new configuration  
9. Runs `ifreload -a` to apply changes  
10. Waits 10 seconds for stabilization  
11. Verifies Proxmox is reachable via SSH  
12. Verifies each required bridge exists and is active  
13. Removes temporary files locally and on Proxmox  
14. Prints a completion summary and next steps  

## Usage

### (One-Time Setup) Create the project directory

This step is only required the first time you set up the automation environment.

```bash
sudo mkdir -p /opt/cyber-range-automation
sudo chown $USER:$USER /opt/cyber-range-automation
```

### (One-Time Setup) Clone the GitHub repository

Only perform this once when initially installing the automation code.

```bash
cd /opt/cyber-range-automation
git clone https://github.com/bkemily/range-research.git .
```
#### If the repository is already cloned

Before running any playbook, always update to the latest version:

```bash
cd /opt/cyber-range-automation
git pull
```
### Run Stage 0

```bash
cd /opt/cyber-range-automation/stage0
ansible-playbook stage0_configure_proxmox_network.yml
```

Specify a custom number of groups:

```bash
ansible-playbook stage0_configure_proxmox_network.yml -e max_student_groups=5
```

## Generated Configuration Summary

The playbook creates:

- `vmbr0` — management  
- `vmbr0.68` — management VLAN  
- `vmbr50` — internet  
- `vmbr51` — closed network  
- `vmbr255000` — instructor LAN  
- `vmbr255GGG` — per-group WAN  
- `vmbrGGG000` — per-group LAN  

A preview of the generated file is displayed during execution.

### Verify Bridges

```bash
# Check active bridges on Proxmox
ip link show | grep vmbr

# Or use the verification script
../scripts/verify_bridges.sh
```

## Verification Performed by the Playbook

After applying configuration, the following are checked:

- SSH connectivity still works  
- All bridges are active  
- Bridges match the expected list for the configured number of groups  

Example bridges for 2 groups:

```
vmbr0
vmbr0.68
vmbr50
vmbr51
vmbr255000
vmbr255001
vmbr001000
vmbr255002
vmbr002000
```

## Safety Features

- **Automatic backup**: Original `/etc/network/interfaces` saved with timestamp
- **Dry-run validation**: Configuration tested before applying
- **Confirmation prompt**: Gives you a chance to review before changes
- **API health check**: Verifies Proxmox is still running after network reload
- **Idempotent**: Safe to run multiple times

## Rollback Procedure

Backups are stored as:

```
/etc/network/interfaces.bak.<epoch>
```

To restore:

```bash
ssh root@192.168.68.89
cp /etc/network/interfaces.bak.TIMESTAMP /etc/network/interfaces
ifreload -a
```

List backups:

```bash
ls -lh /etc/network/interfaces.bak.*
```

## Troubleshooting

### Problem: Network configuration fails to reload

**Solution:**
```bash
# Check network configuration syntax
sudo ifreload -a -n

# View detailed error
sudo journalctl -xe
```

### Problem: Bridges not showing up

**Solution:**
```bash
# Manually reload network
sudo ifreload -a

# Check if bridges exist but are down
ip link show | grep vmbr

# Bring up specific bridge
sudo ip link set vmbr15001 up
```

### Problem: Lost connectivity to Proxmox

**Solution:**
1. Access Proxmox console directly (via vSphere if nested)
2. Restore from backup:
   ```bash
   cp /etc/network/interfaces.backups/interfaces.LATEST /etc/network/interfaces
   ifreload -a
   ```

### Problem: Wrong number of bridges created

**Solution:**
```bash
# Re-run with correct number
sudo ansible-playbook -i ../inventory/hosts.yml stage0_configure_proxmox_network.yml \
  -e max_student_groups=2 \
  -e auto_confirm=true
```

## Verification Checklist

After Stage 0 completes:

- [ ] All required bridges are present (`ip link show | grep vmbr | wc -l`)
- [ ] Proxmox web interface is accessible (https://192.168.68.89:8006)
- [ ] No network errors in logs (`journalctl -xe`)
- [ ] Backup file exists in `/etc/network/interfaces.backups/`
- [ ] Management network still works (can SSH to Proxmox)

Expected bridge count formula: `2 + (max_student_groups * 2)`
- For 2 groups: 6 bridges (vmbr51, vmbr10255, vmbr15001, vmbr15002, vmbr10001, vmbr10002)
- For 5 groups: 12 bridges

## Next Steps

Once Stage 0 completes successfully:

1. Verify all bridges are active
2. Proceed to Stage 1 (Security Onion Bootstrap):
   ```bash
   cd ../stage1
   sudo ansible-playbook -i ../inventory/hosts.yml stage1_bootstrap_security_onion.yml
   ```