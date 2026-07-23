$ErrorActionPreference = 'SilentlyContinue'

Write-Host "Clearing port 8080..."
$p = (Get-NetTCPConnection -LocalPort 8080 | Where-Object { $_.OwningProcess -gt 0 }).OwningProcess
if ($p) { Stop-Process -Id $p -Force }

Write-Host "Starting Oreo Backend..."
Push-Location "$PSScriptRoot\backend"
.\gradlew bootRun
Pop-Location
