# EXPERIMENT EXECUTION GUIDE (In Progress)
## University of West Florida

This guide provides comprehensive instructions for executing full cyber range
experiments using the master orchestration playbook.

# QUICK START

Basic full experiment execution (uses defaults from inventory/hosts.yml):

    ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass

With custom parameters:

    ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass \
      -e "campaign_id=CAMP001" \
      -e "max_student_groups=3" \
      -e "scenario_type=apt" \
      -e "campaign_duration_hours=24"

# CONFIGURATION PARAMETERS

All parameters are optional and default to values in inventory/hosts.yml.
Override any parameter using -e "parameter_name=value"

campaign_id (string, optional)
    Unique identifier for this experiment campaign.
    Default: Uses timestamp if not specified
    Format: CAMP### or descriptive name
    Example: CAMP001, APT_STUDY_JAN2025, RANSOMWARE_TEST_01

max_student_groups (integer: 1-15, optional)
    Number of student groups to deploy.
    Default: Uses value from inventory/hosts.yml
    Each group gets isolated network environment with pfSense, Kali, Metasploitable.
    Example: 3
    Override: -e "max_student_groups=5"

scenario_type (string: apt|ransomware|insider|recon, optional)
    Attack scenario to execute during the campaign.
    Default: Uses value from inventory/hosts.yml or stage2 defaults
    
    - apt: Advanced Persistent Threat simulation
    - ransomware: Ransomware attack chain
    - insider: Insider threat behaviors
    - recon: Reconnaissance and scanning activities
    
    Override: -e "scenario_type=apt"

campaign_duration_hours (integer, optional)
    How long to run the attack campaign (in hours).
    Default: Uses value from inventory/hosts.yml or stage2 defaults
    Maximum: 168 hours (1 week)
    Example: 24 (for 24-hour campaign)
    Override: -e "campaign_duration_hours=48"

## ADDITIONAL OPTIONAL PARAMETERS

start_delay_minutes (integer)
    Random delay before attack campaign starts (in minutes).
    Allows VMs to stabilize and reach steady-state.
    Default: 60 minutes or value from inventory/hosts.yml
    Example: -e "start_delay_minutes=30"

attack_distribution (string: uniform|clustered|random, default: uniform)
    Pattern for distributing attacks across campaign duration.
    Default: uniform or value from inventory/hosts.yml
    
    - uniform: Evenly spaced attacks
    - clustered: Attacks grouped in bursts
    - random: Completely randomized timing
    
    Example: -e "attack_distribution=clustered"

## EXAMPLE COMMANDS

1. SIMPLE RUN - Use all defaults from inventory
   
   ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass

2. FULL EXPERIMENT - APT Scenario, 5 Groups, 48 Hours
   
   ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass \
     -e "campaign_id=APT_RESEARCH_001" \
     -e "max_student_groups=5" \
     -e "scenario_type=apt" \
     -e "campaign_duration_hours=48" \
     -e "attack_distribution=clustered"

3. QUICK TEST - Ransomware Scenario, 2 Groups, 4 Hours
   
   ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass \
     -e "campaign_id=RANSOMWARE_TEST_01" \
     -e "max_student_groups=2" \
     -e "scenario_type=ransomware" \
     -e "campaign_duration_hours=4" \
     -e "start_delay_minutes=15"

4. OVERRIDE STUDENT GROUPS ONLY - Keep other defaults
   
   ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass \
     -e "max_student_groups=7"

5. MAXIMUM SCALE - 15 Groups, Week-long Campaign
   
   ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass \
     -e "campaign_id=LARGE_SCALE_APT_001" \
     -e "max_student_groups=15" \
     -e "scenario_type=apt" \
     -e "campaign_duration_hours=168" \
     -e "attack_distribution=random"

6. CLASSROOM DEMO - Quick insider threat demo
   
   ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass \
     -e "campaign_id=CLASS_DEMO_INSIDER" \
     -e "max_student_groups=1" \
     -e "scenario_type=insider" \
     -e "campaign_duration_hours=2" \
     -e "start_delay_minutes=10"

# EXECUTION FLOW

The playbook executes in this sequence:

1. DISPLAY CONFIGURATION
   - Shows campaign parameters being used
   - Displays which values come from inventory vs. command-line overrides
   - Lists execution sequence

2. STAGE 0: NETWORK TOPOLOGY
   - Creates network bridges and VLANs
   - Configures Proxmox networking based on max_student_groups
   - Prepares VM templates
   - Validates network connectivity

3. STAGE 1: SECURITY ONION
   - Deploys Security Onion VM from template
   - Configures monitoring interfaces
   - Starts Zeek and Suricata workers
   - Validates data collection pipeline

4. STAGE 2: STUDENT ENVIRONMENTS AND CAMPAIGN
   - Deploys pfSense for each group (count = max_student_groups)
   - Deploys Kali and Metasploitable VMs per group
   - Configures network routing
   - Executes attack campaign based on scenario_type
   - Runs for campaign_duration_hours
   - Collects data from Security Onion
   - Performs teardown after completion

5. COMPLETION SUMMARY
   - Displays final summary
   - Shows campaign details
   - Confirms successful completion

Note: All variables passed via -e are automatically available to each stage
      playbook. Variables in inventory/hosts.yml serve as defaults.

# OUTPUT FILES

Experiment outputs are created by individual stage playbooks:

STAGE 0 OUTPUTS:
    Network configuration logs in stage0 directories

STAGE 1 OUTPUTS:
    Security Onion deployment logs
    Security Onion configuration files

STAGE 2 OUTPUTS:
    Campaign execution logs
    Attack timing and sequencing data
    Network traffic captures (via Security Onion)
    
SECURITY ONION DATA COLLECTION:
    /nsm/zeek/logs/           - Zeek network analysis logs
    /nsm/suricata/            - Suricata IDS alerts
    /nsm/pcap/                - Full packet captures
    
Data can be retrieved from Security Onion after campaign completion.

Note: The simple orchestration playbook focuses on execution flow.
      Individual stage playbooks handle their own logging and output.

# MONITORING EXECUTION

During execution, monitor progress:

1. ANSIBLE OUTPUT
   
   The playbook provides visual progress indicators:
   - Stage start/completion messages
   - Configuration display
   - Error notifications (if any occur)

2. STAGE-SPECIFIC LOGS
   
   Each stage creates its own detailed logs:
   - Stage 0: Check Proxmox task logs for network configuration
   - Stage 1: SSH to Security Onion to check deployment status
   - Stage 2: Monitor campaign execution logs

3. PROXMOX WEB INTERFACE
   
   Monitor VM deployment and resource usage via Proxmox GUI:
   - Datacenter -> Tasks (for deployment progress)
   - VM list (to see newly created VMs)
   - Summary -> Resource usage graphs

4. SECURITY ONION STATUS
   
   SSH to Security Onion and check:
   
   ssh securityonion@<SO_IP>
   sudo so-status
   
   This shows Zeek, Suricata, and other service status.

# ERROR HANDLING

## STAGE FAILURES
    If any stage fails, the playbook stops at that point.
    Infrastructure deployed up to the failure point remains.
    
    To clean up after a failure, run teardown playbooks manually:
    
    # Teardown Stage 2 (if it was running)
    ansible-playbook -i inventory/hosts.yml stage2/teardown_campaign.yml --ask-vault-pass
    
    # Teardown Stage 1 (if needed)
    ansible-playbook -i inventory/hosts.yml stage1/teardown_security_onion.yml --ask-vault-pass
    
    # Teardown Stage 0 (if needed)
    ansible-playbook -i inventory/hosts.yml stage0/teardown_network.yml --ask-vault-pass

## NETWORK CONNECTIVITY ISSUES
    Check Proxmox network bridges:
    
    ip link show | grep vmbr
    
    Verify Security Onion interfaces:
    
    ssh securityonion@<SO_IP> "ip link show"

## PFSENSE CONSOLE LOOP (KNOWN ISSUE)
    pfSense VMs may boot into setup wizard despite template config.
    
    Workaround:
    1. Access VM console via Proxmox
    2. Manually assign interfaces:
       - vtnet0 -> WAN
       - vtnet1 -> LAN
    3. Continue playbook execution

# BEST PRACTICES

1. START SMALL
   First run: max_student_groups=1, campaign_duration_hours=2
   Validate entire pipeline before scaling

2. USE INVENTORY DEFAULTS
   Set common values in inventory/hosts.yml
   Override only when needed with -e flags
   
3. USE DESCRIPTIVE CAMPAIGN IDs
   Good: APT_DATASET_JAN2025_RUN1
   Bad: TEST1

4. MONITOR RESOURCE USAGE
   Each group requires:
   - 3 VMs (pfSense, Kali, Metasploitable)
   - ~8GB RAM total
   - ~40GB disk space
   
   10 groups = 30 VMs, 80GB RAM, 400GB disk

5. STAGGER LARGE CAMPAIGNS
   For max_student_groups > 5, increase start_delay_minutes to allow
   Security Onion to stabilize before attack load

6. VERIFY DATA COLLECTION
   After campaign completion, verify Security Onion captured data:
   
   ssh securityonion@<SO_IP>
   sudo so-status
   
   Check Zeek and Suricata logs for campaign timeframe

# TROUBLESHOOTING CHECKLIST

□ Inventory file configured correctly (inventory/hosts.yml)
□ Proxmox credentials in inventory (ansible_user, ansible_password)
□ max_student_groups defined in inventory or passed via -e
□ Network bridges exist on Proxmox (vmbr0, vmbr51, vmbr255xxx)
□ VM templates available:
  - pfsense-template
  - security-onion-template  
  - kali-template
  - metasploitable-template
□ Sufficient Proxmox resources (CPU, RAM, disk)
□ DNS resolution working
□ Ansible controller can reach Proxmox API
□ Python proxmoxer library installed
□ SSH access configured for deployed VMs

# SUPPORT AND DOCUMENTATION

For additional help:

1. Review individual stage playbooks:
   - stage0/stage0_configure_proxmox_network.yml
   - stage1/stage1_bootstrap_security_onion.yml
   - stage2/run_full_campaign.yml

2. Check stage-specific logs in their respective directories

3. Review Proxmox task logs:
   Proxmox GUI -> Datacenter -> Tasks

4. Examine VM console output:
   Proxmox GUI -> VM -> Console

5. Check inventory configuration:
   inventory/hosts.yml - Verify all variables are set correctly
