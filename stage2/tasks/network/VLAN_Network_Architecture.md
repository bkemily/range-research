# Cyber Range VLAN Network Architecture

## Overview

This document explains the VLAN-based network architecture for the automated cyber range, which replaces the previous bridge-per-group approach with a streamlined two-bridge design using VLAN tagging for group isolation.

## High-Level Architecture

### The Two-Bridge Setup

```
Internet/Campus Network
    ↓
vmbr255 (WAN Bridge) ← All pfSense WAN interfaces connect here
    ↓
[pfSense VMs handle routing/NAT/firewall]
    ↓
vmbr100 (LAN Bridge) ← All student VMs connect here with VLAN tags
```

**Key Benefits:**
- Simplified from 30+ bridges to just 2 bridges
- Scales easily from 1 to 15 student groups
- Aligns with UWF-ZeekData24 paper architecture
- VLANs provide network isolation between groups

## Network Addressing Scheme

Following the research paper's IP allocation:

| Network Type | IP Range | VLAN | Purpose |
|--------------|----------|------|---------|
| Router Links | 143.88.0.0/24 | - | pfSense interconnections |
| Student Group 1 | 143.88.1.0/24 | 10 | Group 1 internal network |
| Student Group 2 | 143.88.2.0/24 | 20 | Group 2 internal network |
| Student Group 3 | 143.88.3.0/24 | 30 | Group 3 internal network |
| ... | ... | ... | ... |
| Student Group 15 | 143.88.15.0/24 | 150 | Group 15 internal network |
| Reserved | 143.88.17.0 - 143.88.254.0 | - | Unused (future expansion) |
| Instructor | 143.88.255.0/24 | 255 | Instructor resources |

**VLAN Calculation Formula:** VLAN ID = Group Number × 10

## pfSense VM Configuration

### Hardware Configuration

Each pfSense VM (instructor and student groups) has **two network interfaces**:

```yaml
# All pfSense VMs (regardless of group)
net0: virtio,bridge=vmbr255  # WAN interface
net1: virtio,bridge=vmbr100  # LAN interface (trunk)
```

**Important:** NO VLAN tags are assigned at the Proxmox level for pfSense VMs. VLANs are configured internally within pfSense.

### WAN Interface (vtnet0 → vmbr255)

- Connects to campus network/internet
- Gets IP via DHCP or static assignment from upstream
- Provides internet access for all groups
- Standard pfSense WAN configuration

### LAN Interface (vtnet1 → vmbr100)

This is where VLAN segmentation happens. The LAN interface acts as a **VLAN trunk**, carrying tagged traffic for all student groups.

#### pfSense VLAN Configuration Steps

**For Student Group 1 pfSense:**

1. Navigate to **Interfaces → Assignments → VLANs**
2. Click **Add** to create new VLAN
3. Configure VLAN settings:
   - **Parent Interface:** `vtnet1` (the LAN interface)
   - **VLAN Tag:** `10`
   - **Description:** `Group_01_LAN`
4. Click **Save**

5. Navigate to **Interfaces → Assignments**
6. Click **Add** next to the new VLAN interface
7. Click on the new interface (e.g., OPT1) to configure it
8. Configure interface settings:
   - **Enable:** ✓ Enable interface
   - **Description:** `LAN` or `GROUP01`
   - **IPv4 Configuration Type:** Static IPv4
   - **IPv4 Address:** `143.88.1.1/24`
9. Click **Save** and **Apply Changes**

10. Navigate to **Services → DHCP Server → LAN (or GROUP01)**
11. Configure DHCP:
    - **Enable:** ✓ Enable DHCP server on LAN interface
    - **Range:** From `143.88.1.100` to `143.88.1.200`
    - **DNS Servers:** 8.8.8.8, 8.8.4.4 (or campus DNS)
12. Click **Save**

13. Navigate to **Firewall → Rules → LAN (or GROUP01)**
14. Add rule to allow LAN traffic to WAN:
    - **Action:** Pass
    - **Interface:** LAN
    - **Protocol:** Any
    - **Source:** LAN net
    - **Destination:** Any
15. Click **Save** and **Apply Changes**

**For Student Group 2 pfSense:**
- Repeat above steps
- VLAN Tag: `20`
- IPv4 Address: `143.88.2.1/24`
- DHCP Range: `143.88.2.100` to `143.88.2.200`

**For Student Group 3 pfSense:**
- Repeat above steps
- VLAN Tag: `30`
- IPv4 Address: `143.88.3.1/24`
- DHCP Range: `143.88.3.100` to `143.88.3.200`

**Pattern:** For Group N, use VLAN tag (N × 10) and subnet 143.88.N.0/24

### Instructor pfSense Configuration

The instructor pfSense is configured with **all student group VLANs** plus the instructor VLAN:

- VLAN 10, 20, 30, ... 150 (student groups 1-15)
- VLAN 255 (instructor resources)

This allows the instructor pfSense to route between all groups and manage the entire network.

## Student VM Configuration

Student VMs (Kali Linux, Metasploitable, etc.) connect to vmbr100 **WITH VLAN tags** at the Proxmox level.

### Network Assignment Examples

```yaml
# Student Group 1 VMs
# Kali 1
net0: virtio,bridge=vmbr100,tag=10,firewall=1

# Kali 2
net0: virtio,bridge=vmbr100,tag=10,firewall=1

# Metasploitable Ubuntu
net0: virtio,bridge=vmbr100,tag=10,firewall=1

# Metasploitable Windows
net0: virtio,bridge=vmbr100,tag=10,firewall=1
```

```yaml
# Student Group 2 VMs
# Kali 1
net0: virtio,bridge=vmbr100,tag=20,firewall=1

# Kali 2
net0: virtio,bridge=vmbr100,tag=20,firewall=1

# Metasploitable Ubuntu
net0: virtio,bridge=vmbr100,tag=20,firewall=1

# Metasploitable Windows
net0: virtio,bridge=vmbr100,tag=20,firewall=1
```

### IP Address Assignment

Student VMs receive IP addresses via DHCP from their group's pfSense:

| Group | VLAN | pfSense Gateway | DHCP Range | Example Kali IP |
|-------|------|----------------|------------|-----------------|
| 1 | 10 | 143.88.1.1 | .100 - .200 | 143.88.1.150 |
| 2 | 20 | 143.88.2.1 | .100 - .200 | 143.88.2.150 |
| 3 | 30 | 143.88.3.1 | .100 - .200 | 143.88.3.150 |

## Instructor Resources

### Instructor Kali

```yaml
# Instructor Kali VM
net0: virtio,bridge=vmbr100,tag=255,firewall=1
```

- Connects to VLAN 255 on vmbr100
- Receives IP from instructor pfSense (143.88.255.0/24)
- Can access pfSense WebUIs and Security Onion

### Security Onion

Security Onion monitors all network traffic and has two interfaces:

```yaml
# Security Onion VM
net0: virtio,bridge=vmbr100,tag=255,firewall=1  # Management
net1: virtio,bridge=vmbr100                      # Monitoring (promiscuous)
```

- **net0:** Management interface on instructor VLAN (143.88.255.9/24)
- **net1:** Monitoring interface in promiscuous mode (sees all VLAN traffic)

## Traffic Flow Example

### Scenario: Kali (Group 1) accesses the internet

1. **Kali VM** (143.88.1.150) sends HTTP request
   - Packet tagged with VLAN 10
   - Sent to vmbr100 with tag=10

2. **vmbr100 bridge** forwards tagged packet
   - Only devices listening on VLAN 10 receive it

3. **Group 1 pfSense** receives packet on vtnet1.10 (VLAN 10 subinterface)
   - Recognizes source IP 143.88.1.150 is on LAN subnet
   - Firewall rules allow LAN → WAN traffic

4. **pfSense routing** determines packet needs internet access
   - Applies NAT: changes source IP to pfSense WAN IP
   - Forwards packet out vtnet0 (WAN interface)

5. **Packet exits** via vmbr255 to campus network/internet
   - No VLAN tag on WAN interface
   - Standard routing to internet

6. **Return traffic** follows reverse path
   - Arrives on vtnet0 (WAN)
   - NAT translates back to 143.88.1.150
   - Sent out vtnet1 with VLAN 10 tag
   - vmbr100 delivers only to VLAN 10 devices
   - Kali receives response

### VLAN Isolation

**Group 1 Kali CANNOT communicate with Group 2 Kali** because:
- Group 1 traffic is tagged VLAN 10
- Group 2 traffic is tagged VLAN 20
- vmbr100 enforces VLAN isolation
- Different VLANs = different broadcast domains

**Exception:** Reconnaissance attacks (nmap scans) can discover other groups' IP addresses and attempt connections, which is intentional for the course exercises.

## Automation Integration

### Template-Based Deployment

**pfSense Templates:**
- Instructor pfSense Template (VM ID 8004): Pre-configured with all VLANs
- Student pfSense Template (VM ID 8005): Generic config, customized by `config.sh`

**Student VM Deployment:**
- Ansible playbooks automatically assign correct VLAN tags
- VLAN tag calculation: `{{ group_id | int * 10 }}`
- No manual network configuration required

### config.sh Script

The student pfSense template includes a `config.sh` script that:
- Takes group ID (1-15) as input
- Calculates VLAN tag (group_id × 10)
- Creates VLAN interface on vtnet1
- Assigns IP address (143.88.{group_id}.1/24)
- Configures DHCP server
- Sets up firewall rules

This enables fully automated deployment of student groups.

## Testing and Validation

### Initial Test Setup (3 Groups, 2 Kalis Each)

```
Infrastructure:
├── vmbr255 (WAN Bridge)
│   ├── Instructor pfSense WAN
│   ├── Group 1 pfSense WAN
│   ├── Group 2 pfSense WAN
│   └── Group 3 pfSense WAN
│
└── vmbr100 (LAN Bridge with VLANs)
    ├── VLAN 10 (Group 1)
    │   ├── Group 1 pfSense LAN
    │   ├── Group 1 Kali 1
    │   └── Group 1 Kali 2
    │
    ├── VLAN 20 (Group 2)
    │   ├── Group 2 pfSense LAN
    │   ├── Group 2 Kali 1
    │   └── Group 2 Kali 2
    │
    ├── VLAN 30 (Group 3)
    │   ├── Group 3 pfSense LAN
    │   ├── Group 3 Kali 1
    │   └── Group 3 Kali 2
    │
    └── VLAN 255 (Instructor)
        ├── Instructor pfSense LAN
        ├── Instructor Kali
        └── Security Onion Management
```

### Connectivity Tests

1. **From Kali VM:** `ping 143.88.X.1` (should reach group's pfSense)
2. **From Kali VM:** `ping 8.8.8.8` (should reach internet)
3. **From Kali VM:** `ping 143.88.Y.1` (should fail - different group's pfSense)
4. **From pfSense:** Access WebUI at `https://143.88.X.1` from instructor Kali
5. **From Security Onion:** Verify traffic capture on monitoring interface

### Expected Behavior

✅ **Should Work:**
- Student VMs get DHCP from their group's pfSense
- Internet access via NAT through pfSense
- DNS resolution
- nmap scans to other groups (reconnaissance)

❌ **Should NOT Work:**
- Direct Layer 2 communication between groups
- Student VMs accessing other groups' pfSense WebUIs
- Untagged traffic on vmbr100

## Key Architectural Decisions

1. **VLANs configured inside pfSense, not at Proxmox bridge level**
   - Simplifies VM deployment
   - Templates remain hardware-agnostic
   - Prevents pfSense setup wizard from triggering

2. **Student VMs get VLAN tags at Proxmox level**
   - Explicitly defines group membership
   - Ansible can calculate tags dynamically
   - No configuration needed inside VMs

3. **Two bridges only (vmbr255 and vmbr100)**
   - Massive simplification from 30+ bridges
   - Easier to manage and troubleshoot
   - Better performance (fewer bridge instances)

4. **IP addresses calculated dynamically**
   - Not hardcoded in inventory files
   - Formula-based: 143.88.{group_id}.0/24
   - Scales easily to any number of groups

5. **Instructor Kali on VLAN 255**
   - Part of the VLAN infrastructure
   - Can access all pfSense management interfaces
   - Isolated from student attack traffic by firewall rules

## Troubleshooting

### Common Issues

**Problem:** Kali VM not getting DHCP
- Verify VLAN tag is correct: `tag={{ group_id * 10 }}`
- Check pfSense DHCP server is enabled on VLAN interface
- Verify pfSense VLAN interface has correct IP and is up

**Problem:** No internet access from student VMs
- Check pfSense WAN interface has IP and gateway
- Verify NAT is configured on pfSense
- Check firewall rules allow LAN → WAN traffic

**Problem:** Can't access pfSense WebUI
- Verify you're connecting from correct VLAN
- Check pfSense anti-lockout rule is present
- Ensure instructor Kali is on VLAN 255

**Problem:** VMs in different groups can communicate
- Check VLAN tags are different between groups
- Verify pfSense firewall rules block inter-VLAN traffic
- Ensure vmbr100 is properly configured as VLAN-aware

### Debug Commands

```bash
# On Proxmox host - verify VLAN tagging
bridge vlan show

# Check VM network configuration
qm config <vmid>

# Monitor bridge traffic
tcpdump -i vmbr100 -e -n

# Filter by VLAN
tcpdump -i vmbr100 vlan 10

# Inside pfSense - verify VLAN interfaces
ifconfig vtnet1.10

# Check pfSense routing table
netstat -rn
```

## References

- pfSense VLAN Configuration: https://docs.netgate.com/pfsense/en/latest/vlan/configuration.html
- UWF-ZeekData24 Paper: https://www.mdpi.com/2306-5729/10/5/59
- Proxmox VE Network Configuration: https://pve.proxmox.com/wiki/Network_Configuration

## Revision History

- **2025-12-29:** Initial VLAN architecture documentation
- **Author:** Emily Miller
