# Stage 0: Proxmox Network Configuration

## Overview

Stage 0 configures the Proxmox VE network infrastructure by creating all required bridge interfaces. This is a **one-time setup** that must be completed before deploying any VMs.

## Purpose

- Create Linux bridge interfaces for network isolation
- Configure bridges for instructor and student groups
- Establish network topology for Cyber War Gaming class
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

### Bridge Naming Convention
```
vmbr[Class][Type][Group]

Class:
  1 = Cyber War Gaming
  2 = Ethical Hacking (future)
  3 = Malware Analysis (future)

Type:
  0 = LAN
  5 = WAN

Group:
  001-015 = Student groups
  255 = Instructor
```

## Files

```
stage0/
├── stage0_configure_proxmox_network.yml    # Main playbook
├── templates/
│   └── interfaces.j2                       # Network interfaces template (optional)
└── README.md                               # This file
```

## Configuration

Edit `inventory/group_vars/all.yml` to set the number of student groups:

```yaml
# Number of student groups (1-15)
max_student_groups: 2
```

## Usage

### Run Stage 0

```bash
# From Ubuntu VM
cd /opt/cyber-range-automation/stage0

# Interactive mode (prompts for confirmation)
sudo ansible-playbook -i ../inventory/hosts.yml stage0_configure_proxmox_network.yml

# Automatic mode (no confirmation)
sudo ansible-playbook -i ../inventory/hosts.yml stage0_configure_proxmox_network.yml -e auto_confirm=true

# Custom number of groups
sudo ansible-playbook -i ../inventory/hosts.yml stage0_configure_proxmox_network.yml -e max_student_groups=5
```

### Verify Bridges

```bash
# Check active bridges on Proxmox
ip link show | grep vmbr

# Or use the verification script
../scripts/verify_bridges.sh
```

## What the Playbook Does

1. **Validates environment** - Checks Proxmox version and accessibility
2. **Creates backup** - Saves `/etc/network/interfaces` with timestamp to `/etc/network/interfaces.backups/`
3. **Checks existing bridges** - Shows currently configured bridges
4. **Generates configuration** - Creates complete network interfaces file
5. **Validates configuration** - Dry-run test before applying changes
6. **Prompts for confirmation** - Review before making changes (unless auto_confirm=true)
7. **Applies changes** - Replaces `/etc/network/interfaces`
8. **Reloads network** - Activates bridges with `ifreload -a`
9. **Verifies bridges** - Confirms all bridges are active
10. **Health check** - Ensures Proxmox API is still responsive

## Safety Features

- **Automatic backup**: Original `/etc/network/interfaces` saved with timestamp
- **Dry-run validation**: Configuration tested before applying
- **Confirmation prompt**: Gives you a chance to review before changes
- **API health check**: Verifies Proxmox is still running after network reload
- **Idempotent**: Safe to run multiple times

## Rollback Procedure

If something goes wrong:

```bash
# List available backups
ls -lh /etc/network/interfaces.backups/

# Restore from backup
sudo cp /etc/network/interfaces.backups/interfaces.YYYYMMDD_HHMMSS /etc/network/interfaces

# Reload network
sudo ifreload -a

# Verify
ip link show | grep vmbr
```

## Expected Output

```
TASK [Display stage information]
ok: [localhost] => 
  msg: |
    ========================================
    STAGE 0: Proxmox Network Configuration
    ========================================
    Bridges to configure:
      - vmbr51 (Spark WAN)
      - vmbr10255 (Instructor LAN)
      - vmbr15001-vmbr15002 (Student WANs)
      - vmbr10001-vmbr10002 (Student LANs)
    ========================================

TASK [Backup current interfaces file]
changed: [localhost]

TASK [Display backup location]
ok: [localhost] =>
  msg: "Backup created: /etc/network/interfaces.backups/interfaces.20250129_143022"

TASK [Display completion summary]
ok: [localhost] =>
  msg: |
    ========================================
    Stage 0: Network Configuration Complete
    ========================================
    
    Bridges configured: 6
    
    Active bridges:
    vmbr0
    vmbr51
    vmbr10001
    vmbr10002
    vmbr10255
    vmbr15001
    vmbr15002
    
    Next step: Run Stage 1 bootstrap
      ansible-playbook stage1_bootstrap_security_onion.yml
    ========================================
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

## References

- [Proxmox Network Configuration](https://pve.proxmox.com/wiki/Network_Configuration)
- [Linux Bridge Documentation](https://wiki.debian.org/BridgeNetworkConnections)
- Main project documentation: `../docs/ARCHITECTURE.md`