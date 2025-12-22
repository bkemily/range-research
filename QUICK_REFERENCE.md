################################################################################
# CYBER RANGE QUICK REFERENCE CARD (In Progress)
# Common Experiment Scenarios
################################################################################

┌──────────────────────────────────────────────────────────────────────────────┐
│ SCENARIO 1: FIRST-TIME FULL DEPLOYMENT                                      │
│ Use Case: Initial system setup and validation                               │
└──────────────────────────────────────────────────────────────────────────────┘

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml \
  -e "campaign_id=INITIAL_VALIDATION" \
  -e "max_student_groups=1" \
  -e "scenario_type=recon" \
  -e "campaign_duration_hours=2"

Expected Duration: ~45-60 minutes
Resource Usage: 3 VMs, 8GB RAM, 40GB disk
Purpose: Validate entire pipeline works end-to-end


┌──────────────────────────────────────────────────────────────────────────────┐
│ SCENARIO 2: RESEARCH DATASET GENERATION - APT                               │
│ Use Case: Generate labeled APT detection dataset                            │
└──────────────────────────────────────────────────────────────────────────────┘

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml \
  -e "campaign_id=APT_DATASET_2025_01" \
  -e "max_student_groups=5" \
  -e "scenario_type=apt" \
  -e "campaign_duration_hours=48" \
  -e "attack_distribution=clustered" \
  -e "start_delay_minutes=90"

Expected Duration: ~50 hours (48hr campaign + 2hr setup/teardown)
Resource Usage: 15 VMs, 40GB RAM, 200GB disk
Data Output: ~100GB of labeled network traffic (Zeek, Suricata, PCAP)


┌──────────────────────────────────────────────────────────────────────────────┐
│ SCENARIO 3: CLASSROOM DEMONSTRATION                                         │
│ Use Case: Live demo of ransomware attack for students                       │
└──────────────────────────────────────────────────────────────────────────────┘

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml \
  -e "campaign_id=CLASS_DEMO_$(date +%Y%m%d)" \
  -e "max_student_groups=1" \
  -e "scenario_type=ransomware" \
  -e "campaign_duration_hours=1" \
  -e "start_delay_minutes=10"

Expected Duration: ~30 minutes
Resource Usage: 3 VMs, 8GB RAM, 40GB disk
Note: Use Proxmox console for live viewing during attack


┌──────────────────────────────────────────────────────────────────────────────┐
│ SCENARIO 4: USE INVENTORY DEFAULTS                                          │
│ Use Case: Simple run with all values from inventory/hosts.yml               │
└──────────────────────────────────────────────────────────────────────────────┘

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml

Expected Duration: Depends on inventory configuration
Resource Usage: Depends on max_student_groups in inventory
Note: Cleanest approach - manage config in inventory, not command line


┌──────────────────────────────────────────────────────────────────────────────┐
│ SCENARIO 5: OVERRIDE STUDENT GROUPS ONLY                                    │
│ Use Case: Keep all inventory defaults except number of groups               │
└──────────────────────────────────────────────────────────────────────────────┘

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml \
  -e "max_student_groups=7"

Expected Duration: Depends on other inventory settings
Resource Usage: 21 VMs (7 groups × 3 VMs), 56GB RAM
Purpose: Quick scaling test without changing other parameters


┌──────────────────────────────────────────────────────────────────────────────┐
│ SCENARIO 6: MAXIMUM SCALE TEST                                              │
│ Use Case: Stress test infrastructure with maximum groups                    │
└──────────────────────────────────────────────────────────────────────────────┘

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml \
  -e "campaign_id=SCALE_TEST_10GROUPS" \
  -e "max_student_groups=10" \
  -e "scenario_type=apt" \
  -e "campaign_duration_hours=72" \
  -e "attack_distribution=random" \
  -e "start_delay_minutes=120"

Expected Duration: ~75 hours
Resource Usage: 30 VMs, 80GB RAM, 400GB disk
WARNING: Ensure Proxmox host has sufficient resources
Recommendation: Monitor during first 2 hours for stability


┌──────────────────────────────────────────────────────────────────────────────┐
│ SCENARIO 7: COMPARATIVE STUDY - MULTIPLE SCENARIOS                          │
│ Use Case: Generate datasets for all attack types with same conditions       │
└──────────────────────────────────────────────────────────────────────────────┘

# Run all scenarios sequentially

for scenario in apt ransomware insider recon; do
  ansible-playbook -i inventory/hosts.yml run_full_experiment.yml \
    -e "campaign_id=COMPARATIVE_${scenario}_2025" \
    -e "max_student_groups=3" \
    -e "scenario_type=${scenario}" \
    -e "campaign_duration_hours=24" \
    -e "attack_distribution=uniform"
  
  sleep 300  # 5 minute cool-down between campaigns
done

Expected Duration: ~100 hours total (4 campaigns × 25 hours)
Resource Usage: Same 9 VMs reused across campaigns
Data Output: 4 comparable datasets for scenario analysis


┌──────────────────────────────────────────────────────────────────────────────┐
│ SCENARIO 8: QUICK VALIDATION AFTER CODE CHANGES                             │
│ Use Case: Verify playbook changes didn't break anything                     │
└──────────────────────────────────────────────────────────────────────────────┘

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml \
  -e "campaign_id=VALIDATION_$(date +%Y%m%d_%H%M%S)" \
  -e "max_student_groups=1" \
  -e "scenario_type=recon" \
  -e "campaign_duration_hours=1" \
  -e "start_delay_minutes=5"

Expected Duration: ~20 minutes
Purpose: Fast validation of playbook modifications
Use: Run after any Ansible playbook updates


┌──────────────────────────────────────────────────────────────────────────────┐
│ SCENARIO 9: WEEKEND UNATTENDED RUN                                          │
│ Use Case: Long campaign that runs autonomously over weekend                 │
└──────────────────────────────────────────────────────────────────────────────┘

# Run on Friday afternoon, completes Sunday evening

nohup ansible-playbook -i inventory/hosts.yml run_full_experiment.yml \
  -e "campaign_id=WEEKEND_APT_$(date +%Y%m%d)" \
  -e "max_student_groups=5" \
  -e "scenario_type=apt" \
  -e "campaign_duration_hours=60" \
  -e "attack_distribution=random" \
  > weekend_run.log 2>&1 &

# Monitor progress
tail -f weekend_run.log

Expected Duration: ~62 hours (60hr campaign + setup/teardown)
Recommendation: Test shorter run first to ensure stability


┌──────────────────────────────────────────────────────────────────────────────┐
│ SCENARIO 10: MINIMAL COMMAND - INVENTORY DEFAULTS                           │
│ Use Case: Simplest possible execution using all inventory settings          │
└──────────────────────────────────────────────────────────────────────────────┘

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml

Expected Duration: Based on inventory configuration
Resource Usage: Based on max_student_groups in inventory
Purpose: Cleanest approach - all config in version-controlled inventory


┌──────────────────────────────────────────────────────────────────────────────┐
│ COMMON PARAMETER COMBINATIONS                                               │
└──────────────────────────────────────────────────────────────────────────────┘

INVENTORY DEFAULTS (Recommended)
  No -e parameters needed
  All values from inventory/hosts.yml
  
QUICK TEST (Development)
  max_student_groups=1
  campaign_duration_hours=1
  start_delay_minutes=5

STANDARD RESEARCH RUN
  max_student_groups=3-5
  campaign_duration_hours=24-48
  start_delay_minutes=60-90
  attack_distribution=uniform or clustered

CLASSROOM DEMONSTRATION
  max_student_groups=1
  campaign_duration_hours=1-2
  start_delay_minutes=10-15
  scenario_type=ransomware (most dramatic)

PRODUCTION DATASET GENERATION
  max_student_groups=5-10
  campaign_duration_hours=72-168
  start_delay_minutes=90-120
  attack_distribution=random


┌──────────────────────────────────────────────────────────────────────────────┐
│ RESOURCE ESTIMATION TABLE                                                   │
└──────────────────────────────────────────────────────────────────────────────┘

Groups  VMs   RAM(GB)  Disk(GB)  Setup Time  Campaign Time (24hr)
------  ----  -------  --------  ----------  --------------------
   1      3       8       40      ~15 min        24 hr 15 min
   2      6      16       80      ~20 min        24 hr 20 min
   3      9      24      120      ~25 min        24 hr 25 min
   5     15      40      200      ~35 min        24 hr 35 min
  10     30      80      400      ~60 min        25 hr

Note: 
- RAM and Disk include Security Onion overhead
- Setup Time = Stage 0 + Stage 1 + Stage 2 deployment
- Add campaign_duration_hours to Setup Time for total
- Teardown adds ~5-10 minutes


┌──────────────────────────────────────────────────────────────────────────────┐
│ ATTACK SCENARIO CHARACTERISTICS                                             │
└──────────────────────────────────────────────────────────────────────────────┘

APT (Advanced Persistent Threat)
  Duration: 24-168 hours
  Characteristics: Low-and-slow, multi-stage, persistence mechanisms
  Data Volume: High (sustained activity)
  Detection Difficulty: Hard (evasive techniques)

RANSOMWARE
  Duration: 1-12 hours
  Characteristics: Fast, aggressive, encryption behaviors
  Data Volume: Medium (bursty traffic)
  Detection Difficulty: Medium (distinctive patterns)

INSIDER
  Duration: 12-72 hours
  Characteristics: Legitimate credentials, data exfiltration
  Data Volume: Medium (periodic activity)
  Detection Difficulty: Hard (authorized access)

RECON (Reconnaissance)
  Duration: 1-8 hours
  Characteristics: Scanning, enumeration, probing
  Data Volume: Very High (many connections)
  Detection Difficulty: Easy (noisy scans)


┌──────────────────────────────────────────────────────────────────────────────┐
│ CLEANUP COMMANDS                                                             │
└──────────────────────────────────────────────────────────────────────────────┘

Manual cleanup if experiment fails or needs to be stopped:

# Full teardown (all stages in reverse order)
ansible-playbook -i inventory/hosts.yml stage2/teardown_campaign.yml
ansible-playbook -i inventory/hosts.yml stage1/teardown_security_onion.yml
ansible-playbook -i inventory/hosts.yml stage0/teardown_network.yml

# Teardown only student environments (preserve Security Onion)
ansible-playbook -i inventory/hosts.yml stage2/teardown_campaign.yml

# Nuclear option - remove ALL cyber range VMs (use with caution)
for vm in $(pvesh get /cluster/resources --type vm --output-format json | \
            jq -r '.[] | select(.name | contains("cyber")) | .vmid'); do
  qm stop $vm --skiplock
  qm destroy $vm --skiplock --purge
done


┌──────────────────────────────────────────────────────────────────────────────┐
│ MONITORING DURING EXECUTION                                                  │
└──────────────────────────────────────────────────────────────────────────────┘

# Watch Ansible output (run from separate terminal)
# The playbook itself provides visual progress

# Monitor Proxmox task queue
watch -n 5 'pvesh get /cluster/tasks --limit 20'

# Check Security Onion status
ssh securityonion@<SO_IP> "sudo so-status"


# Check stage-specific logs (paths depend on stage playbooks)
# Stage 0: Check Proxmox task logs
# Stage 1: SSH to Security Onion for deployment status
# Stage 2: Monitor campaign execution output