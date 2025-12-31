#!/bin/bash

CSV_FILE="/home/kali/nmap_scan.csv"

TIMESTAMP=$(date +"%m/%d/%Y %H:%M:%S")
GROUP_NUMBER="1"
TACTIC_ID="T1595"
SOURCE_IP="143.88.1.18"
SOURCE_PORT=""
TARGET_IP="143.88.2.1-21"
TARGET_PORT="445"
START_TIME_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START_YEAR=$(date +"%Y")
START_MONTH=$(date +"%m")
START_DAY=$(date +"%d")
START_TIME=$(date +"%H:%M:%S")

nmap -T4 -p $TARGET_PORT $TARGET_IP -oX nmapOut.xml

END_YEAR=$(date +"%Y")
END_MONTH=$(date +"%m")
END_DAY=$(date +"%d")
END_TIME=$(date +"%H:%M:%S")

echo "$TIMESTAMP,$GROUP_NUMBER,$TACTIC_ID,$SOURCE_IP,$SOURCE_PORT,$TARGET_IP,$TARGET_PORT,$START_TIME_DATE,$START_YEAR,$START_MONTH,$START_DAY,$START_TIME,$END_YEAR,$END_MONTH,$END_DAY,$END_TIME" >> "$CSV_FILE"
