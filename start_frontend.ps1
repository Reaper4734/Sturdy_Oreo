# Ensure the script runs from the frontend directory regardless of where it was launched
Set-Location $PSScriptRoot

$port = 3000

Write-Host "Checking if port $port is in use..."
$connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue

if ($connections) {
    # Extract unique PIDs (in case there are multiple connections on the same port)
    $pids = $connections | Select-Object -ExpandProperty OwningProcess -Unique
    Write-Host "Port $port is in use by PID(s): $pids. Killing processes..."
    
    foreach ($id in $pids) {
        Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
        Write-Host "Killed PID $id."
    }
    
    # Wait a moment to ensure the OS has fully released the port
    Start-Sleep -Seconds 2
    Write-Host "Port $port is now clear."
} else {
    Write-Host "Port $port is already free."
}

Write-Host "Starting Flutter frontend on port $port..."
Set-Location "$PSScriptRoot\frontend"
flutter run -d web-server --web-port=$port
