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
START_TIME_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
TACTIC_ID="T1053.003"
HOSTNAME=$(hostname)
HOST_IP=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
GROUP_NUMBER=$(echo "$HOST_IP" | cut -d. -f3)

RAND_ID=$((RANDOM % 10000))
CRON_JOB_PATH="/etc/cron.d/.sysmaint_$RAND_ID"
PAYLOAD_PATH="/tmp/.sysmaint_$RAND_ID.sh"

echo '#!/bin/bash' > "$PAYLOAD_PATH"
echo 'logger "logrotate: rotating logs for apache2"' >> "$PAYLOAD_PATH"
chmod +x "$PAYLOAD_PATH"

echo "*/30 * * * * root $PAYLOAD_PATH" | sudo tee "$CRON_JOB_PATH" > /dev/null

sleep 1  # Simulate persistence duration

END_TIME_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

sudo rm -f "$CRON_JOB_PATH" "$PAYLOAD_PATH"

echo "$TIMESTAMP,$GROUP_NUMBER,$HOSTNAME,$TACTIC_ID,$HOST_IP,$START_TIME_DATE,$END_TIME_DATE" >> "$CSV_FILE"