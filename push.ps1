param (
    [string]$Message = "Auto-commit updates"
)
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
Write-Host "Pushing to git with message: '$Message'..."
git add .
git commit -m $Message
git push
Pop-Location
