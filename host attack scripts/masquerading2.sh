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

# MITRE: T1036
TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%SZ")
export HOST_IP=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
export HOSTNAME=$(hostname)
GROUP_NUMBER=$(echo $HOST_IP | cut -d. -f3)
TACTIC_ID="T1036.005"
START_TIME_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.%6NZ")

RAND_ID=$((RANDOM % 10000))
CRON_PATH="/etc/cron.d/logrotate.daily_$RAND_ID"
PAYLOAD="/tmp/logrotate_$RAND_ID.sh"

echo "@reboot root /tmp/logrotate.sh" | sudo tee "$CRON_PATH"

# Fake payload
echo "@reboot root $PAYLOAD" | sudo tee "$CRON_PATH" > /dev/null
echo '#!/bin/bash' > "$PAYLOAD"
echo 'touch /var/log/.logrotate_fake_success' >> "$PAYLOAD"
chmod +x "$PAYLOAD"

# Simulated dwell time
sleep 1

END_TIME_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.%6NZ")
sudo rm -f "$CRON_PATH" "$PAYLOAD"

echo "$TIMESTAMP,$GROUP_NUMBER,$HOSTNAME,$TACTIC_ID,$HOST_IP,$START_TIME_DATE,$END_TIME_DATE" >> "$CSV_FILE"