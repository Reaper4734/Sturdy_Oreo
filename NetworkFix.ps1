# Requires Admin Privileges to reset network settings
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script needs to run as Administrator. Elevating..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "      Network Troubleshooter & Fixer          " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/6] Releasing IP Address..."
ipconfig /release | Out-Null

Write-Host "[2/6] Flushing DNS Cache..."
ipconfig /flushdns | Out-Null

Write-Host "[3/6] Renewing IP Address..."
ipconfig /renew | Out-Null

Write-Host "[4/6] Resetting Winsock Catalog..."
netsh winsock reset | Out-Null

Write-Host "[5/6] Resetting TCP/IP Stack..."
netsh int ip reset | Out-Null

Write-Host "[6/6] Restarting Active Network Adapters..."
$adapters = Get-NetAdapter -Physical | Where-Object Status -eq "Up"
foreach ($adapter in $adapters) {
    Write-Host "      Restarting adapter: $($adapter.Name)"
    Disable-NetAdapter -Name $adapter.Name -Confirm:$false
    Start-Sleep -Seconds 2
    Enable-NetAdapter -Name $adapter.Name -Confirm:$false
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host " Troubleshooting completed successfully!      " -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: Please RESTART the computer for the changes to fully take effect." -ForegroundColor Yellow
Write-Host ""
Pause
