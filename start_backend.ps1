# Ensure the script runs from the correct directory regardless of where it was launched
Set-Location $PSScriptRoot
if (Test-Path ".\backend\gradlew.bat") {
    Set-Location ".\backend"
}

$port = 8080

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

Write-Host "`nEnsuring database is running via Docker..."

# 1. Check if Docker daemon is running; if not, attempt to launch Docker Desktop
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

# 2. Start PostgreSQL container
docker-compose up -d

# 3. Wait for PostgreSQL to actively accept TCP connections on port 5432
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
    Read-Host "Press Enter to exit..."
    exit 1
}

if (!(Test-Path ".\build\libs\oreo-backend-0.0.1-SNAPSHOT.jar")) {
    Write-Host "`nBuilding backend JAR..."
    .\gradlew.bat bootJar -x test
}

Write-Host "`nStarting Spring Boot backend on port $port..."
java -Xmx2g -jar .\build\libs\oreo-backend-0.0.1-SNAPSHOT.jar
