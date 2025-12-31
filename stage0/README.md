# Stage 0: Proxmox Network Configuration

## Overview

Stage 0 configures the Proxmox VE network infrastructure by creating required infrastructure and VLAN bridge interfaces. This is a **one-time setup** that must be completed before deploying any VMs.

## Purpose

- Create Linux bridge interfaces for infrastructure and VLAN networks
- Configure bridges for Proxmox management and internet connectivity
- Establish foundational network topology for cyber range
- Ensure safe rollback through automatic timestamped backups
- Prepare Proxmox for Security Onion deployment

## Prerequisites

- Ubuntu VM with Proxmox VE installed
- SSH/sudo access to Proxmox host
- Ansible 2.9+ installed on Ubuntu VM
- Network connectivity to Proxmox management interface

## Bridge Naming Schema (Exact as Implemented)

### **Infrastructure Bridges**
| Bridge | Purpose |
|--------|---------|
| `vmbr0` | Proxmox management bridge (VLAN-aware) |
| `vmbr0.68` | Management VLAN (192.168.68.89/24) |
| `vmbr50` | Internet (Spark WAN) |
| `vmbr51` | Closed network (VLAN-aware) |

### **VLAN Bridges**
| Bridge | Purpose |
|--------|---------|
| `vmbr255` | VLAN WAN (configurable via `bridges.vlan_wan`) |
| `vmbr100` | VLAN LAN, VLAN-aware (configurable via `bridges.vlan_lan`) |

## Files

```
stage0/
├── stage0_final.yml   # Main playbook
└── README.md          # This file
```

## What the Playbook Actually Does

1. Displays stage information and bridge plan  
2. Tests SSH connectivity to Proxmox  
3. Creates timestamped backup of `/etc/network/interfaces`  
4. Generates network configuration for infrastructure and VLAN bridges only  
5. Writes config to `/tmp/interfaces.new` locally  
6. Transfers it to Proxmox with SCP  
7. Applies new configuration  
8. Runs `ifreload -a` to apply changes  
9. Waits 10 seconds for stabilization  
10. Enables promiscuous mode on student group bridges (from variable)
11. Verifies Proxmox is reachable via SSH  
12. Verifies each required infrastructure bridge exists and is active  
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
ansible-playbook -i inventory/hosts.yml stage0_final.yml
```

## Generated Configuration Summary

The playbook creates:

- `vmbr0` — management  
- `vmbr0.68` — management VLAN  
- `vmbr50` — internet  
- `vmbr51` — closed network  
- `vmbr255` — VLAN WAN (configurable)
- `vmbr100` — VLAN LAN (configurable)

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
- All infrastructure bridges are active  
- Bridges match the expected list (infrastructure and VLAN bridges only)

Example bridges verified:

```
vmbr0
vmbr0.68
vmbr50
vmbr51
vmbr255
vmbr100
```

## Safety Features

- **Automatic backup**: Original `/etc/network/interfaces` saved with timestamp
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
sudo ip link set vmbr255 up
```

### Problem: Lost connectivity to Proxmox

**Solution:**
1. Access Proxmox console directly (via vSphere if nested)
2. Restore from backup:
   ```bash
   cp /etc/network/interfaces.bak.LATEST /etc/network/interfaces
   ifreload -a
   ```

## Verification Checklist

After Stage 0 completes:

- [ ] All infrastructure bridges are present (`ip link show | grep vmbr`)
- [ ] Proxmox web interface is accessible (https://192.168.68.89:8006)
- [ ] No network errors in logs (`journalctl -xe`)
- [ ] Backup file exists (`/etc/network/interfaces.bak.*`)
- [ ] Management network still works (can SSH to Proxmox)

Expected infrastructure bridge count: 6 bridges
- `vmbr0`, `vmbr0.68`, `vmbr50`, `vmbr51`, `vmbr255`, `vmbr100`

## Next Steps

Once Stage 0 completes successfully:

1. Verify all infrastructure bridges are active
2. Add student group bridges manually if needed
3. Proceed to Stage 1 (Security Onion Bootstrap)