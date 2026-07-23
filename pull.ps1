$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
Write-Host "Pulling latest from git..."
git pull
Pop-Location
