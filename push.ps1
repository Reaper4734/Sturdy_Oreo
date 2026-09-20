param (
    [string]$Message = "Auto-commit updates",
    [switch]$DeployEc2
)

if ($DeployEc2) {
    & "$PSScriptRoot\deploy.ps1" -Message $Message
} else {
    & "$PSScriptRoot\deploy.ps1" -Message $Message -SkipEc2
}

