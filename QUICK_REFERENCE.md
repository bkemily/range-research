# QUICK REFERENCE CARD (In Progress)
# Common Experiment Scenarios

## SCENARIO 1: FIRST-TIME FULL DEPLOYMENT
Use Case: Initial system setup and validation

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass \
  -e "campaign_id=INITIAL_VALIDATION" \
  -e "max_student_groups=1" \
  -e "scenario_type=recon" \
  -e "campaign_duration_hours=2"

Purpose: Validate entire pipeline works end-to-end

## SCENARIO 2: RESEARCH DATASET GENERATION - APT
Use Case: Generate labeled APT detection dataset

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass \
  -e "campaign_id=APT_DATASET_2025_01" \
  -e "max_student_groups=5" \
  -e "scenario_type=apt" \
  -e "campaign_duration_hours=48" \
  -e "attack_distribution=clustered" \
  -e "start_delay_minutes=90"

Purpose: 


## SCENARIO 3: CLASSROOM DEMONSTRATION
Use Case: Live demo of ransomware attack for students

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass \
  -e "campaign_id=CLASS_DEMO_$(date +%Y%m%d)" \
  -e "max_student_groups=1" \
  -e "scenario_type=ransomware" \
  -e "campaign_duration_hours=1" \
  -e "start_delay_minutes=10"

Purpose:


## SCENARIO 4: USE INVENTORY DEFAULTS
Use Case: Simple run with all values from inventory/hosts.yml

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass

Purpose: 


## SCENARIO 5: OVERRIDE STUDENT GROUPS ONLY
Use Case: Keep all inventory defaults except number of groups

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass \
  -e "max_student_groups=7"

Purpose: Quick scaling test without changing other parameters


## SCENARIO 6: MAXIMUM SCALE TEST
Use Case: Stress test infrastructure with maximum groups

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass \
  -e "campaign_id=SCALE_TEST_10GROUPS" \
  -e "max_student_groups=10" \
  -e "scenario_type=apt" \
  -e "campaign_duration_hours=72" \
  -e "attack_distribution=random" \
  -e "start_delay_minutes=120"

Purpose: Full War Gaming class mockup and test
WARNING: Ensure Proxmox host has sufficient resources
Recommendation: Monitor during first 2 hours for stability


## SCENARIO 7: COMPARATIVE STUDY - MULTIPLE SCENARIOS
Use Case: Generate datasets for all attack types with same conditions

# Run all scenarios sequentially

for scenario in apt ransomware insider recon; do
  ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass \
    -e "campaign_id=COMPARATIVE_${scenario}_2025" \
    -e "max_student_groups=3" \
    -e "scenario_type=${scenario}" \
    -e "campaign_duration_hours=24" \
    -e "attack_distribution=uniform"
  
  sleep 300  # 5 minute cool-down between campaigns
done

Purpose: 4 comparable datasets for scenario analysis


## SCENARIO 8: QUICK VALIDATION AFTER CODE CHANGES
Use Case: Verify playbook changes didn't break anything

ansible-playbook -i inventory/hosts.yml run_full_experiment.yml --ask-vault-pass \
  -e "campaign_id=VALIDATION_$(date +%Y%m%d_%H%M%S)" \
  -e "max_student_groups=1" \
  -e "scenario_type=recon" \
  -e "campaign_duration_hours=1" \
  -e "start_delay_minutes=5"

Purpose: Fast validation of playbook modifications
Use: Run after any Ansible playbook updates


# COMMON PARAMETER COMBINATIONS

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


# ATTACK SCENARIO CHARACTERISTICS

APT (Advanced Persistent Threat)
  Characteristics: Low-and-slow, multi-stage, persistence mechanisms
  Data Volume: High (sustained activity)
  Detection Difficulty: Hard (evasive techniques)

RANSOMWARE
  Characteristics: Fast, aggressive, encryption behaviors
  Data Volume: Medium (bursty traffic)
  Detection Difficulty: Medium (distinctive patterns)

RECON (Reconnaissance)
  Characteristics: Scanning, enumeration, probing
  Data Volume: Very High (many connections)
  Detection Difficulty: Easy (noisy scans)


# CLEANUP COMMANDS

Manual cleanup if experiment fails or needs to be stopped:

## Full teardown
ansible-playbook -i inventory/hosts.yml stage2/teardown.yml --ask-vault-pass


# MONITORING DURING EXECUTION (from a seperate terminal window)

## Watch Ansible output
The playbook itself provides visual progress

## Monitor Proxmox task queue
watch -n 5 'pvesh get /cluster/tasks --limit 20'

## Check Security Onion status
ssh securityonion@<SO_IP> "sudo so-status"


## Check stage-specific logs (paths depend on stage playbooks)
Stage 0: Check Proxmox task logs
Stage 1: SSH to Security Onion for deployment status
Stage 2: Monitor campaign execution output