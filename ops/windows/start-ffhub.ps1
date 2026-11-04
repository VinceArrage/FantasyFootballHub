# Runs Fantasy Football Hub at http://localhost:3000 with background jobs inside
# Puma. Restarts it if it ever exits. Started at logon by register-startup.ps1.
$ErrorActionPreference = "Continue"
$app = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$env:Path = "C:\Ruby34-x64\bin;" + $env:Path
$env:SOLID_QUEUE_IN_PUMA = "1"
Set-Location $app

while ($true) {
  Remove-Item -ErrorAction SilentlyContinue "tmp\pids\server.pid"
  "$(Get-Date -Format s) starting" | Out-File -Append -Encoding utf8 "log\ffhub-service.log"
  # Rails already writes log\development.log (rotated); only start/exit lines go here.
  & ruby bin/rails server -b 127.0.0.1 -p 3000 *> $null
  "$(Get-Date -Format s) exited with $LASTEXITCODE, restarting in 10s" | Out-File -Append -Encoding utf8 "log\ffhub-service.log"
  Start-Sleep -Seconds 10
}
