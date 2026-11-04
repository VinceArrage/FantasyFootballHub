# One-time setup: start Fantasy Football Hub hidden every time you log in.
# Run from PowerShell:  powershell -ExecutionPolicy Bypass -File ops\windows\register-startup.ps1
# Undo with:           Unregister-ScheduledTask -TaskName FantasyFootballHub -Confirm:$false
$script = Join-Path $PSScriptRoot "start-ffhub.ps1"
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
  -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) `
  -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName "FantasyFootballHub" -Action $action -Trigger $trigger -Settings $settings -Force
Start-ScheduledTask -TaskName "FantasyFootballHub"
Write-Host "Registered. Open http://localhost:3000"
