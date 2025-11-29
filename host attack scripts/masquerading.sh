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

RAND_ID=$((RANDOM % 100000))
FAKE_LS="/tmp/ls_$RAND_ID"
cat <<EOF > "$FAKE_LS"
#!/bin/bash
logger "[ATTACK_LOG][$TIMESTAMP] masq ls command executed"
EOF

chmod +x "$FAKE_LS"

ORIGINAL_PATH="$PATH"
PATH="/tmp:$PATH"

ls

PATH="$ORIGINAL_PATH"

END_TIME_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.%6NZ")

rm -f "$FAKE_LS"

echo "$TIMESTAMP,$GROUP_NUMBER,$HOSTNAME,$TACTIC_ID,$HOST_IP,$START_TIME_DATE,$END_TIME_DATE" >> "$CSV_FILE"