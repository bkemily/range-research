# Inventory Directory

This directory contains the Ansible inventory configuration for the cyber range automation system.

## Structure

```
inventory/
├── hosts.yml                    # Main inventory file (host definitions)
├── group_vars/
│   ├── all.yml                  # Variables for all hosts
│   └── pve.yml                  # Proxmox-specific variables
└── README.md                    # This file
```

## Files

### hosts.yml

Defines all hosts in the cyber range infrastructure:

- **Control Node**: Ubuntu VM running Ansible (localhost)
- **Proxmox Host**: hm-hcr-08 (192.168.68.89)
- **Security Onion**: Orchestrator and network monitor
- **Spark pfSense**: Internet gateway
- **Instructor Infrastructure**: pfSense router and Kali attack platform
- **Student Groups**: 2 groups, each with:
  - pfSense router
  - 2x Kali Linux VMs
  - 1x Ubuntu target
  - 1x Windows target

### group_vars/all.yml

Global variables available to all playbooks:

- Campaign configuration (class code, duration, etc.)
- Proxmox API settings
- VM template paths
- VM ID allocation scheme
- Network configuration (bridges, IP ranges)
- Student group definitions
- Attack script configurations
- Mission log settings
- Data collection paths
- Security Onion configuration

### group_vars/pve.yml

Proxmox-specific configuration:

- API authentication (token-based)
- Storage pool definitions
- VM hardware defaults
- Import/clone settings
- Network bridge verification
- Backup and snapshot settings

## Usage

### View Inventory

```bash
# List all hosts
ansible-inventory -i inventory/hosts.yml --list

# Show specific host details
ansible-inventory -i inventory/hosts.yml --host group1_kali1

# Show inventory graph
ansible-inventory -i inventory/hosts.yml --graph
```

### Test Connectivity

```bash
# Ping all hosts
ansible all -i inventory/hosts.yml -m ping

# Ping Proxmox
ansible pve -i inventory/hosts.yml -m ping

# Ping student group 1
ansible group1 -i inventory/hosts.yml -m ping
```

### Run Playbooks

```bash
# Use the inventory with any playbook
ansible-playbook -i inventory/hosts.yml stage0/stage0_final.yml --ask-vault-pass
ansible-playbook -i inventory/hosts.yml stage1/stage1_bootstrap_security_onion.yml --ask-vault-pass
```

## Customization

### Adding More Student Groups

To add Group 3, edit `hosts.yml` and `group_vars/all.yml`:

**hosts.yml:**
```yaml
students:
  children:
    group3:
      hosts:
        group3_pfsense:
          ansible_host: 143.88.3.1
          vm_id: 203
          group_id: 3
        # ... add other Group 3 VMs
```

**group_vars/all.yml:**
```yaml
max_student_groups: 3

student_groups:
  - id: 3
    name: "group3"
    wan_bridge: "vmbr15003"
    lan_bridge: "vmbr10003"
    wan_ip: "143.88.0.10/30"
    wan_gateway: "143.88.0.9"
    lan_network: "143.88.3.0/24"
    lan_gateway: "143.88.3.1"
```

### Changing VM IDs

Edit the `vm_ids` section in `group_vars/all.yml`:

```yaml
vm_ids:
  spark_pfsense: 50        # Change to your preferred ID
  instructor_pfsense: 100
  # ...
```

### Updating Template Paths

Edit the `templates` section in `group_vars/all.yml`:

```yaml
templates:
  kali: "/mnt/pve/ovfstore/TEMPLATE-kali-NEW.ovf"
  # ...
```

### Changing Network Configuration

Edit the `bridges` and `ip_ranges` sections in `group_vars/all.yml`:

```yaml
bridges:
  instructor_lan: "vmbr10255"  # Change bridge names
  # ...

ip_ranges:
  instructor_network: "143.88.255.0/24"  # Change IP ranges
  # ...
```

## Variables Reference

### Common Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `max_student_groups` | Number of student groups | `2` |
| `class_code` | Course class code | `1` |
| `course_prefix` | Course identifier | `CIS4416` |
| `campaign_duration_hours` | Default campaign length | `24` |

### Proxmox Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `proxmox_api_host` | Proxmox API endpoint | `192.168.68.89` |
| `proxmox_node` | Proxmox node name | `hm-hcr-08` |
| `storage` | Default VM storage | `raid-lvm` |
| `ovf_storage` | Template storage | `ovfstore` |

### Network Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `bridges.instructor_lan` | Instructor LAN bridge | `vmbr10255` |
| `bridges.spark_wan` | Spark WAN bridge | `vmbr51` |
| `ip_ranges.instructor_network` | Instructor subnet | `143.88.255.0/24` |

### VM ID Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `vm_ids.security_onion` | Security Onion VM ID | `159` |
| `vm_ids.instructor_pfsense` | Instructor pfSense ID | `100` |
| `vm_ids.student_pfsense_base` | Student pfSense base ID | `200` |

## Security Considerations

### Sensitive Data

The following variables contain sensitive information:

- `proxmox_api_token_secret` - Proxmox API token
- `pfsense.default_password` - pfSense admin password

**What We Use:**

1. **Use Ansible Vault for production:**
   ```bash
   # Encrypt sensitive variables
   ansible-vault encrypt group_vars/all.yml
   
   # Run playbook with vault password
   ansible-playbook -i inventory/hosts.yml playbook.yml --ask-vault-pass
   ```

### Token-based Authentication

The inventory is configured to use Proxmox API tokens (more secure than passwords):

```yaml
api_token_id: "ansible-token"
api_token_secret: {{ vault_proxmox_api_token }}
```

**To create a new API token in Proxmox:**

1. Log in to Proxmox web UI
2. Navigate to: Datacenter → Permissions → API Tokens
3. Click "Add" and create token for user `root@pam`
4. Copy the token secret (shown only once)
5. Update `api_token_secret` in `group_vars/all.yml`

## Validation

### Check Inventory Syntax

```bash
# Validate YAML syntax
ansible-inventory -i inventory/hosts.yml --list > /dev/null && echo "Syntax OK"

# Check for undefined variables
ansible-playbook -i inventory/hosts.yml playbook.yml --syntax-check
```

### Verify Hosts

```bash
# List all hosts
ansible-inventory -i inventory/hosts.yml --graph

# Expected output:
# @all:
#   |--@control_node:
#   |  |--localhost
#   |--@cyber_range:
#   |  |--@instructor:
#   |  |  |--instructor_kali
#   |  |  |--instructor_pfsense
#   |  |--@security_onion:
#   |  |  |--so1
#   |  |--@spark:
#   |  |  |--spark_pfsense
#   |  |--@students:
#   |  |  |--@group1:
#   |  |  |  |--group1_kali1
#   |  |  |  |--group1_kali2
#   |  |  |  |--group1_pfsense
#   |  |  |  |--group1_ubuntu
#   |  |  |  |--group1_windows
#   |  |  |--@group2:
#   |  |  |  |--group2_kali1
#   |  |  |  |--group2_kali2
#   |  |  |  |--group2_pfsense
#   |  |  |  |--group2_ubuntu
#   |  |  |  |--group2_windows
#   |--@pve:
#   |  |--hm-hcr-08
```

### Test Variable Resolution

```bash
# Show all variables for a host
ansible-inventory -i inventory/hosts.yml --host group1_kali1 --yaml

# Check specific variable
ansible -i inventory/hosts.yml localhost -m debug -a "var=max_student_groups"
```

## Troubleshooting

### Problem: Inventory file not found

**Solution:**
```bash
# Always use absolute or relative path
ansible-playbook -i inventory/hosts.yml playbook.yml

# Or set ANSIBLE_INVENTORY environment variable
export ANSIBLE_INVENTORY=inventory/hosts.yml
ansible-playbook playbook.yml
```

### Problem: Variables not being applied

**Solution:**
```bash
# Check variable precedence
ansible-inventory -i inventory/hosts.yml --host hostname --yaml

# Verify group_vars files are in correct location
ls -la inventory/group_vars/
```

### Problem: YAML syntax errors

**Solution:**
```bash
# Use yamllint to check syntax
yamllint inventory/hosts.yml
yamllint inventory/group_vars/*.yml

# Common issues:
# - Inconsistent indentation (use 2 spaces)
# - Missing colons
# - Incorrect list syntax
```

## Migration from INI Format

If migrating from the old `inventory.ini`:

**Old (INI):**
```ini
[pve]
hm-hcr-08 ansible_host=192.168.68.89

[pve:vars]
api_user=root@pam
```

**New (YAML):**
```yaml
pve:
  hosts:
    hm-hcr-08:
      ansible_host: 192.168.68.89
      api_user: root@pam
```

## References

- [Ansible Inventory Documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)
- [Inventory Variables](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html#organizing-host-and-group-variables)
- [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- Main project documentation: `../docs/ARCHITECTURE.md`
