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

# 2. Start Database (PostgreSQL via Docker Compose)
Write-Host "`nEnsuring database is running via Docker..."
cd backend

docker info > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker daemon is not running. Launching Docker Desktop..."
    if (Test-Path "C:\Program Files\Docker\Docker\Docker Desktop.exe") {
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    }
    
    $dockerTimeout = 45
    $dockerElapsed = 0
    Write-Host "Waiting for Docker daemon to become ready (up to $dockerTimeout s)..."
    while ($dockerElapsed -lt $dockerTimeout) {
        docker info > $null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Docker daemon is ready!"
            break
        }
        Start-Sleep -Seconds 2
        $dockerElapsed += 2
    }
}

docker-compose up -d

# Wait for PostgreSQL to accept connections on port 5432
$dbPort = 5432
$dbTimeout = 30
$dbElapsed = 0
$dbReady = $false

Write-Host "Waiting for PostgreSQL to accept connections on port $dbPort..."
while ($dbElapsed -lt $dbTimeout) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect("127.0.0.1", $dbPort)
        if ($tcp.Connected) {
            $tcp.Close()
            $dbReady = $true
            Write-Host "PostgreSQL is UP and ready on port $dbPort!"
            break
        }
    } catch {
        # Retry until ready
    }
    Start-Sleep -Seconds 1
    $dbElapsed++
}

if (-not $dbReady) {
    Write-Warning "Could not connect to PostgreSQL on port $dbPort after $dbTimeout seconds."
    Write-Warning "Please ensure Docker Desktop is running, then re-run this script."
    cd ..
    Read-Host "Press Enter to exit..."
    exit 1
}

cd ..

# 3. Start Backend in a separate window (so we can see its logs)
Write-Host "`nStarting Spring Boot backend in a new window..."
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; if (!(Test-Path '.\build\libs\oreo-backend-0.0.1-SNAPSHOT.jar')) { .\gradlew.bat bootJar -x test }; java -Xmx2g -jar .\build\libs\oreo-backend-0.0.1-SNAPSHOT.jar"

# 4. Start Frontend in the current window (so you can use hot-reload 'r' keys)
Write-Host "`nStarting Flutter frontend in this window..."
cd frontend
flutter run -d web-server --web-port=3000
