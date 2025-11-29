#How to test scripts:
#Enable scripts to run: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#.\script.ps1
#Even with Bypass, some systems enforce signing. If needed, run: 
#.\Unblock-File -Path .\create_user_attack.ps1


sPowerShell\v1.0\powershell.e# Cleanup script - delete queued users
$deleteFile = "C:\Temp\users_to_delete.txt"

if (Test-Path $deleteFile) {
    $users = Get-Content $deleteFile
    foreach ($u in $users) {
        Write-Output "Deleting user: $u"
        net user $u /delete
    }
    Clear-Content $deleteFile
}
