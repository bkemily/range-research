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
$TACTIC_ID = "T1053.003"
$START_TIME_DATE = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

$hostUser = $env:USERNAME
$triggerType = "AtLogon"

# Random task name and payload path for safe repeatability
$randId = Get-Random -Minimum 10000 -Maximum 99999
$taskName = "WinUpdateTask_$randId"
$payloadPath = "C:\Users\Public\fake_update_$randId.bat"

# === Simulated Realistic Payload Message ===
$messages = @(
    "Starting telemetry agent...",
    "Connecting to license service...",
    "Validating boot configuration...",
    "Launching scheduled system check...",
    "Applying group policy template..."
)
$payloadMessage = $messages | Get-Random

try {
    @"
@echo off
$payloadMessage
"@ | Out-File -FilePath $payloadPath -Encoding ascii
    $success = 1
} catch {
    $success = 0
}

# === Create and Delete Scheduled Task using schtasks.exe ===
if ($success -eq 1) {
    try {
        schtasks.exe /Create /SC ONLOGON /TN $taskName /TR "`"$payloadPath`"" /RL HIGHEST /F | Out-Null
        Start-Sleep -Seconds 1  # Simulate dwell time
        schtasks.exe /Delete /TN $taskName /F | Out-Null
        $success = 1
    } catch {
        $success = 0
    }
}

$END_TIME_DATE = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# Append to CSV
"$TIMESTAMP,$GROUP_NUMBER,$HOSTNAME,$TACTIC_ID,$HOST_IP,$START_TIME_DATE,$END_TIME_DATE" | Out-File -FilePath $CSV_FILE -Encoding utf8 -Append

# Cleanup payload
Remove-Item -Path $payloadPath -ErrorAction SilentlyContinue