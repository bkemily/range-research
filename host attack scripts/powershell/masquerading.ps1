#How to test scripts:
#Enable scripts to run: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#.\script.ps1
#Even with Bypass, some systems enforce signing. If needed, run: 
#.\Unblock-File -Path .\create_user_attack.ps1


$CSV_FILE = "C:\Users\Public\attack.csv"

# Define column names
$C1 = "ts"
$C2 = "group_id"
$C3 = "hostname"
$C4 = "mitre_attack_technique"
$C5 = "ip"
$C6 = "start_time_date"
$C7 = "end_time_date"

# If CSV doesn't exist, create it with headers
if (-not (Test-Path $CSV_FILE)) {
    "$C1,$C2,$C3,$C4,$C5,$C6,$C7" | Out-File -FilePath $CSV_FILE -Encoding utf8
}

# === Metadata ===
$TIMESTAMP = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$HOSTNAME = $env:COMPUTERNAME
$ipLine = ipconfig | Where-Object { $_ -match "IPv4 Address" }
$HOST_IP = if ($ipLine) { ($ipLine -split ":")[1].Trim() } else { "0.0.0.0" }
$GROUP_NUMBER = ($HOST_IP -split "\.")[2]
$TACTIC_ID = "T1056.001"
$START_TIME_DATE = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# Randomized masquerade filename
$prefix = "svc"
$rand = Get-Random -Minimum 1000 -Maximum 9999
$masqueradeFileName = "$prefix$rand.bat"
$payloadPath = "C:\Users\Public\$masqueradeFileName"
# Random harmless-looking messages
$messages = @(
    "Updating policy settings...",
    "Loading user configuration...",
    "Initializing network service...",
    "Checking file system integrity..."
)
$selectedMessage = $messages | Get-Random

$backtick = [char]96
# Write and run disguised payload
try {
    "@echo off$backtickn$selectedMessage" | Out-File -FilePath $payloadPath -Encoding ascii
    Start-Process -FilePath $payloadPath -WindowStyle Hidden -Wait
    $success = 1
} catch {
    $success = 0
}

$END_TIME_DATE = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# Append to CSV
"$TIMESTAMP,$GROUP_NUMBER,$HOSTNAME,$TACTIC_ID,$HOST_IP,$START_TIME_DATE,$END_TIME_DATE" | Out-File -FilePath $CSV_FILE -Encoding utf8 -Append

# Cleanup
Remove-Item $payloadPath -ErrorAction SilentlyContinue