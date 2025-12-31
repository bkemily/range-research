# Stage 1: Security Onion VM Deployment

## Overview

Stage 1 creates and configures the Security Onion VM with comprehensive network monitoring interfaces. This VM serves as the centralized orchestration and monitoring platform for the entire Cyber Range environment. This is a **one-time setup** that must be completed after Stage 0.

## Purpose

- Create Security Onion VM
- Configure hardware
- Assign network interfaces
- Prepare VM for manual Security Onion installation
- Enable monitoring of all network segments (instructor + student groups)

## Prerequisites

- Stage 0 completed (all network bridges created)
- SSH access to Proxmox host
- Ansible 2.9+ installed on control node
- Security Onion ISO available in Proxmox ISO_Library storage
  - ISO: `securityonion-2.4.180-20250916.iso`
- Sufficient storage (minimum 2TB available)

## Network Interface Schema

Security Onion is connected to all network segments for comprehensive monitoring:

### **Management Interface**
| Interface | Bridge | Purpose |
|-----------|--------|---------|
| `net0` | `vmbr` | Management/IP communication (143.88.255.9) |

### **Infrastructure Monitoring**
| Interface | Bridge | Purpose |
|-----------|--------|---------|
| `net1` | `vmbr50` | Spark WAN monitoring (internet gateway) |

### **Student Group Monitoring** (Dynamic)
| Interface | Bridge | Purpose |
|-----------|--------|---------|
| `netX` | `vmbrXX` |  |


## Files

```
stage1/
├── stage1_bootstrap_security_onion.yml   # Main playbook
├── files/
│   ├── auto_runner.sh                    # Auto-runner script (future use)
│   ├── start_campaign.sh                 # Manual campaign script (future use)
│   └── auto-runner.service               # Systemd service (future use)
└── README.md                             # This file
```

## What the Playbook Actually Does

1. **Display Stage Information**
   - Shows VM configuration (memory, CPUs, disk, network interfaces)
   - Displays total interface count

2. **Pre-deployment Validation**
   - Tests SSH connectivity to Proxmox
   - Generates dynamic bridge list
   - Verifies all required bridges exist (infrastructure + student groups)
   - Checks if VM 159 already exists (prevents overwrites)
   - Verifies Security Onion ISO exists in ISO_Library

3. **Create Security Onion VM**
   - Creates VM 159 with proper hardware configuration
   - Allocates 32GB RAM, 8 CPU cores, q35 machine type
   - Uses OVMF (UEFI) BIOS instead of legacy SeaBIOS

4. **Configure Storage**
   - Creates 2TB primary disk on `local-lvm` storage
   - Attaches Security Onion ISO to IDE2
   - Creates 4MB EFI disk for UEFI boot

5. **Set Boot Order and Options**
   - Configures boot order: `scsi0;ide2` (disk first, then ISO)
   - Enables hotplug for disk, network, USB
   - Enables tablet mode for console pointer
   - Enables KVM hardware virtualization

6. **Assign Network Interfaces**
   - Assigns all required interfaces

7. **Start VM**
   - Starts VM (boots from ISO)
   - Waits 30 seconds for boot
   - Verifies VM is running

8. **Display Completion Summary**
   - Shows VM details and network configuration
   - Provides manual installation instructions
   - Lists next steps

## Usage

### Run Stage 1

```bash
cd /opt/cyber-range-automation/stage1
ansible-playbook -i ../inventory/hosts.yml stage1_bootstrap_security_onion.yml --ask-vault-pass
```

## VM Configuration

### Hardware Specifications
```yaml
VM ID: 159
Name: so-master
Memory: 32000 MB (31.25 GiB)
CPUs: 8 cores (1 socket)
Machine: q35 (modern chipset)
BIOS: ovmf (UEFI)
SCSI Controller: virtio-scsi-single
```

### Storage Configuration
```yaml
Primary Disk: 2000 GB (2TB) on local-lvm
EFI Disk: 4 MB on local-lvm
ISO: ISO_Library:iso/securityonion-2.4.180-20250916.iso
```

### Network Configuration
- 


## Manual Installation Required

**IMPORTANT:** After the playbook completes, you must manually install Security Onion through the Proxmox console.

## Verification

### Verify VM Creation

```bash
# Check VM exists and is running
ssh root@192.168.68.89 "qm status 159"
# Expected: status: running

# View VM configuration
ssh root@192.168.68.89 "qm config 159"

# Check network interfaces
ssh root@192.168.68.89 "qm config 159 | grep net"
```

## Safety Features

- **VM Existence Check:** Prevents overwriting existing VM 159
- **Bridge Verification:** Ensures all required bridges exist before deployment
- **ISO Verification:** Checks ISO availability (non-fatal warning if check fails)
- **Idempotent:** Safe to re-run after destroying VM
- **Rollback Support:** Easy to destroy and recreate VM

## Rollback Procedure

If you need to start over:

```bash
# Stop and destroy the VM
ssh root@192.168.68.89 "qm stop 159"
ssh root@192.168.68.89 "qm destroy 159"

# Re-run Stage 1
cd /opt/cyber-range-automation/stage1
ansible-playbook -i ../inventory/hosts.yml stage1_bootstrap_security_onion.yml --ask-vault-pass
```

**Note:** Destroying the VM removes all disks. You will need to reinstall Security Onion.

## Troubleshooting

### Problem: Playbook fails with "security_onion is undefined"

**Cause:** Missing or incorrectly named inventory file

**Solution:**
```bash
# Verify inventory structure
ls -la /opt/cyber-range-automation/inventory/group_vars/

# File must be named: all.yml (not vars_all.yml)
# If wrong, rename it:
cd /opt/cyber-range-automation/inventory/group_vars/
mv vars_all.yml all.yml
```

### Problem: Bridge verification fails

**Cause:** Stage 0 not completed or bridges missing

**Solution:**
```bash
# Verify bridges exist
ssh root@192.168.68.89 "ip link show | grep vmbr"

# Count bridges
ssh root@192.168.68.89 "ip link show | grep -c vmbr"

# Re-run Stage 0 if bridges missing
cd /opt/cyber-range-automation/stage0
ansible-playbook stage0_final.yml --ask-vault-pass
```

### Problem: ISO not found

**Cause:** Security Onion ISO not uploaded to Proxmox

**Solution:**
```bash
# Check ISO exists
ssh root@192.168.68.89 "pvesm list ISO_Library | grep securityonion"

# If missing, upload ISO to Proxmox:
# 1. Download Security Onion ISO
# 2. Upload to Proxmox ISO_Library via web UI
# 3. Verify filename matches: securityonion-2.4.180-20250916.iso
```

### Problem: Insufficient storage space

**Cause:** Not enough free space on local-lvm for 2TB disk

**Solution:**
```bash
# Check storage usage
ssh root@192.168.68.89 "pvesm status"

# If insufficient, either:
# 1. Free up space by removing unused VMs/disks
# 2. Use different storage in inventory/group_vars/all.yml
#    Change: storage: "local-lvm"
#    To: storage: "your-storage-name"
```

### Problem: VM won't start

**Cause:** Hardware configuration issue or ISO mount problem

**Solution:**
```bash
# Check VM configuration
ssh root@192.168.68.89 "qm config 159"

# Check VM status and logs
ssh root@192.168.68.89 "qm status 159"
ssh root@192.168.68.89 "qm showcmd 159"

# Try starting manually
ssh root@192.168.68.89 "qm start 159"

# Check Proxmox logs
ssh root@192.168.68.89 "journalctl -xe | grep 'qemu\|kvm'"
```

### Problem: Can't access Security Onion Web UI after installation

**Cause:** Incorrect IP configuration or network issue

**Solution:**
```bash
# Check from Proxmox console if VM has correct IP
# Access Proxmox UI -> VM 159 -> Console
# Login and check: ip addr show

# Verify IP is 143.88.255.9
# If not, reconfigure:
sudo so-setup network

# Test connectivity from control node
ping 143.88.255.9
ssh analyst@143.88.255.9
```

## Verification Checklist

After Stage 1 automation completes:

- [ ] VM 159 exists (`qm status 159` shows running)
- [ ] VM has 32GB RAM (`qm config 159 | grep memory`)
- [ ] VM has 8 CPU cores (`qm config 159 | grep cores`)
- [ ] VM has 2TB disk (`qm config 159 | grep scsi0`)
- [ ] VM has correct number of network interfaces (`qm config 159 | grep -c net`)
- [ ] ISO is attached (`qm config 159 | grep ide2`)
- [ ] EFI disk exists (`qm config 159 | grep efidisk0`)
- [ ] VM is running and accessible via console
- [ ] VM boots from ISO and shows Security Onion installer

## Next Steps

Once Stage 1 completes successfully:

1. **Complete Manual Installation** (30-60 minutes)
   - Follow installation guide above
   - Configure management IP: 143.88.255.9/24
   - Set credentials

2. **Proceed to Stage 2** (After installation)
   - Stage 2.1: Bootstrap Security Onion (install Ansible, copy playbooks)
   - Stage 2.2: Deploy infrastructure VMs
   - Stage 2.3: Configure network and start campaign

## Additional Resources

- **Security Onion Documentation:** https://docs.securityonion.net/
- **Proxmox VE Documentation:** https://pve.proxmox.com/wiki/
- **Stage 0 README:** `../stage0/README.md`

