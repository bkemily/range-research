#Run scripts:
#1. Make script executable: chmod +x create_user_attack.sh
#2. Run script: sudo ./create_user_attack.sh
#3. Check logs: sudo tail -f /var/log/auth.log

#!/bin/bash
CSV_FILE="/home/vagrant/attack.csv"

#************ Column Names *************#
C1="ts"
C2="group_id"
C3="hostname"
C4="mitre_attack_technique"
C5="ip"
C6="start_time_date"
C7="end_time_date"

if ! [ -f $CSV_FILE ]; then
    echo "\"$C1\",\"$C2\",\"$C3\",\"$C4\",\"$C5\",\"$C6\",\"$C7\"" >> $CSV_FILE
fi

TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%SZ")
START_TIME_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.%6NZ")
TACTIC_ID="T1053.003"
HOSTNAME=$(hostname)
HOST_IP=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
GROUP_NUMBER=$(echo "$HOST_IP" | cut -d. -f3)

RAND_ID=$((RANDOM % 10000))
CRON_FILE="/etc/cron.d/systemtask_$RAND_ID"
TASK_FILE="/tmp/systemtask_$RAND_ID.sh"

MESSAGES=("cron.daily: cleanup completed" "logrotate: rotated apache logs" "cron job finished" "daily temp cleanup")
RAND_MSG=${MESSAGES[$RANDOM % ${#MESSAGES[@]}]}

echo "@reboot root $TASK_FILE" | sudo tee "$CRON_FILE" > /dev/null
echo "logger \"$RAND_MSG\"" | sudo tee -a "$TASK_FILE" > /dev/null
sudo chmod +x "$TASK_FILE"

sleep 1

END_TIME_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.%6NZ")
sudo rm -f "$CRON_FILE" "$TASK_FILE"

echo "$TIMESTAMP,$GROUP_NUMBER,$HOSTNAME,$TACTIC_ID,$HOST_IP,$START_TIME_DATE,$END_TIME_DATE" >> "$CSV_FILE"