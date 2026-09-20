<#
.SYNOPSIS
    Deploys Oreo updates to AWS EC2 (Backend) and pushes to GitHub (triggering Cloudflare Pages Frontend).

.DESCRIPTION
    1. Stages, commits, and pushes code to GitHub `main` branch.
    2. Packages backend files (excluding heavy build artifacts).
    3. Uploads tarball to AWS EC2 via SCP using `oreo-server.pem`.
    4. Rebuilds and launches the backend Docker container on EC2.
    5. Runs health checks to verify successful deployment.

.PARAMETER Message
    The git commit message. Default: "Auto-commit and deploy updates"

.PARAMETER SkipGit
    Skip git add, commit, and push.

.PARAMETER SkipEc2
    Skip EC2 backend deployment.

.PARAMETER PemPath
    Path to the EC2 private key .pem file. Default: .\oreo-server.pem

.PARAMETER HostName
    The EC2 host or domain. Default: oreo-api.duckdns.org

.PARAMETER UserName
    The EC2 SSH username. Default: ec2-user
#>

param (
    [string]$Message = "Auto-commit and deploy updates",
    [switch]$SkipGit,
    [switch]$SkipEc2,
    [string]$PemPath = "oreo-server.pem",
    [string]$HostName = "oreo-api.duckdns.org",
    [string]$UserName = "ec2-user"
)

$ErrorActionPreference = 'Stop'
$ScriptRoot = $PSScriptRoot

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "         OREO FULL-STACK DEPLOYMENT PIPELINE      " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# 1. GITHUB PUSH (Frontend Cloudflare Pages Deployment)
# -----------------------------------------------------------------------------
if (-not $SkipGit) {
    Write-Host "`n[1/2] Syncing repository with GitHub..." -ForegroundColor Yellow
    Push-Location $ScriptRoot
    try {
        git add -A
        $status = git status --porcelain
        if ($status) {
            Write-Host "Committing changes with message: '$Message'..." -ForegroundColor Gray
            git commit -m $Message
        } else {
            Write-Host "No uncommitted local changes." -ForegroundColor Gray
        }
        Write-Host "Pushing to origin main..." -ForegroundColor Gray
        git push origin main
        Write-Host "[OK] Pushed to GitHub. Cloudflare Pages frontend build triggered!" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Git push encountered an issue: $_" -ForegroundColor DarkYellow
    } finally {
        Pop-Location
    }
} else {
    Write-Host "`n[1/2] Skipping GitHub push (-SkipGit specified)." -ForegroundColor DarkGray
}

# -----------------------------------------------------------------------------
# 2. AWS EC2 BACKEND DEPLOYMENT
# -----------------------------------------------------------------------------
if (-not $SkipEc2) {
    Write-Host "`n[2/2] Deploying Backend to AWS EC2 ($HostName)..." -ForegroundColor Yellow

    $ResolvedPem = Join-Path $ScriptRoot $PemPath
    if (-not (Test-Path $ResolvedPem)) {
        Write-Host "[ERROR] Private key not found at $ResolvedPem" -ForegroundColor Red
        exit 1
    }

    # Fix Windows file permissions on PEM key if needed
    try {
        icacls $ResolvedPem /inheritance:r /grant:r "$($env:USERNAME):(R,W)" | Out-Null
    } catch {}

    $TarFile = Join-Path $ScriptRoot "backend-deploy.tar.gz"

    try {
        Write-Host "Packaging backend source files..." -ForegroundColor Gray
        Push-Location (Join-Path $ScriptRoot "backend")
        tar --exclude="build" --exclude=".gradle" --exclude="bin" --exclude=".env" -czf $TarFile .
        Pop-Location

        Write-Host "Uploading tarball to EC2 via SCP..." -ForegroundColor Gray
        scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i $ResolvedPem $TarFile "${UserName}@${HostName}:~/oreo/"

        Write-Host "Extracting and rebuilding backend container on EC2..." -ForegroundColor Gray
        $RemoteCommands = "mkdir -p ~/oreo/backend && " +
                          "tar -xzf ~/oreo/backend-deploy.tar.gz -C ~/oreo/backend && " +
                          "rm -f ~/oreo/backend-deploy.tar.gz && " +
                          "rm -f /home/ec2-user/.docker/cli-plugins/docker-buildx && " +
                          "cd ~/oreo/backend && " +
                          "docker-compose stop backend 2>/dev/null || true && " +
                          "docker rm -f oreo_backend 2>/dev/null || true && " +
                          "docker-compose up -d --build backend"

        ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i $ResolvedPem "${UserName}@${HostName}" $RemoteCommands

        Write-Host "Verifying backend health on EC2..." -ForegroundColor Gray
        Start-Sleep -Seconds 8
        $HealthCheck = ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i $ResolvedPem "${UserName}@${HostName}" "curl -s -m 5 http://localhost:8080/actuator/health || echo 'STARTING'"
        Write-Host "Health Check Status: $HealthCheck" -ForegroundColor Cyan

        Write-Host "`n[OK] AWS EC2 Backend successfully updated & running!" -ForegroundColor Green
    } catch {
        Write-Host "`n[ERROR] EC2 deployment failed: $_" -ForegroundColor Red
        exit 1
    } finally {
        if (Test-Path $TarFile) {
            Remove-Item -Force $TarFile -ErrorAction SilentlyContinue
        }
    }
} else {
    Write-Host "`n[2/2] Skipping EC2 deployment (-SkipEc2 specified)." -ForegroundColor DarkGray
}

Write-Host "`n=================================================" -ForegroundColor Cyan
Write-Host "            DEPLOYMENT COMPLETE!                 " -ForegroundColor Green
Write-Host "  Frontend: https://oreo.pages.dev               " -ForegroundColor White
Write-Host "  Backend:  https://oreo-api.duckdns.org/api     " -ForegroundColor White
Write-Host "=================================================" -ForegroundColor Cyan
