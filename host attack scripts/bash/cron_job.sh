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

# MITRE: T1053.003 - Cron Job (Persistence)
TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%SZ")
export HOST_IP=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
export HOSTNAME=$(hostname)
GROUP_NUMBER=$(echo $HOST_IP | cut -d. -f3)
TACTIC_ID="T1053.003"
START_TIME_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.%6NZ")

PAYLOAD_FILE="/tmp/.cron_payload_$(date +%s%N).sh"
RANDOM_MSGS=("logrotate completed" "cron.daily executed" "cleanup job done")
MSG=${RANDOM_MSGS[$RANDOM % ${#RANDOM_MSGS[@]}]}

echo '#!/bin/bash' > "$PAYLOAD_FILE"
echo "logger \"$MSG\"" >> "$PAYLOAD_FILE"
chmod +x "$PAYLOAD_FILE"

crontab -l 2>/dev/null | grep -q "$PAYLOAD_FILE" || \
(crontab -l 2>/dev/null; echo "@reboot $PAYLOAD_FILE") | crontab -

sleep 1

END_TIME_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.%6NZ")

crontab -l 2>/dev/null | grep -v "$PAYLOAD_FILE" | crontab -
rm -f "$PAYLOAD_FILE"

echo "$TIMESTAMP,$GROUP_NUMBER,$HOSTNAME,$TACTIC_ID,$HOST_IP,$START_TIME_DATE,$END_TIME_DATE" >> "$CSV_FILE"