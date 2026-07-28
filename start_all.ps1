# Ensure the script runs from the correct directory regardless of where it was launched
Set-Location $PSScriptRoot

function Clear-Port {
    param([int]$port)
    Write-Host "Checking if port $port is in use..."
    $connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue

    if ($connections) {
        $pids = $connections | Select-Object -ExpandProperty OwningProcess -Unique
        Write-Host "Port $port is in use by PID(s): $pids. Killing processes..."
        
        foreach ($id in $pids) {
            Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
            Write-Host "Killed PID $id."
        }
        
        Start-Sleep -Seconds 2
        Write-Host "Port $port is now clear."
    } else {
        Write-Host "Port $port is already free."
    }
}

# 1. Clear both ports
Clear-Port -port 8080
Clear-Port -port 3000

# 2. Start Backend in a separate window (so we can see its logs)
Write-Host "`nStarting Spring Boot backend in a new window..."
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; .\gradlew.bat bootRun"

# 3. Start Frontend in the current window (so you can use hot-reload 'r' keys)
Write-Host "`nStarting Flutter frontend in this window..."
cd frontend
flutter run -d web-server --web-port=3000
