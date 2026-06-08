$ErrorActionPreference = "Stop"

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Clear-Host

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "        AutoDM Cloud Installer          " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Helper function to handle transient network errors (like 504 Gateway Timeout)
function Invoke-WebRequestWithRetry {
    param(
        [string]$Uri,
        [string]$OutFile,
        [int]$MaxRetries = 5
    )
    $retryCount = 0
    while ($true) {
        try {
            if ([string]::IsNullOrEmpty($OutFile)) {
                return Invoke-WebRequest -Uri $Uri -UseBasicParsing -ErrorAction Stop
            } else {
                # Critical Fix: The PowerShell progress bar slows down the network stream on large files, 
                # often causing GitHub's CDN to close the connection with a 504 Timeout. We must disable it during download.
                $global:ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
                $global:ProgressPreference = 'Continue'
                return
            }
        } catch {
            $retryCount++
            if ($retryCount -ge $MaxRetries) {
                throw "Request failed after $MaxRetries attempts: $($_.Exception.Message)"
            }
            Write-Host "Network error ($($_.Exception.Message)). Retrying in 3 seconds... ($retryCount/$MaxRetries)" -ForegroundColor DarkYellow
            
            # Clean up corrupted 0-byte file if download failed mid-way
            if (-not [string]::IsNullOrEmpty($OutFile) -and (Test-Path $OutFile)) {
                Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
            }
            Start-Sleep -Seconds 3
        }
    }
}

try {
    # Version file with cache-buster to prevent stuck 504s on GitHub's CDN
    $cacheBuster = [guid]::NewGuid().ToString()
    $versionUrl = "https://raw.githubusercontent.com/avm3005/detaroxzAutoDM/main/UpdSystem/version.txt?t=$cacheBuster"

    Write-Host "Checking latest version..." -ForegroundColor Yellow

    $versionRaw = (Invoke-WebRequestWithRetry -Uri $versionUrl).Content.Trim()
    $version = $versionRaw -replace '^v', ''

    Write-Host "Latest Version: v$version" -ForegroundColor Green

    # Download URL
    $zipName = "AutoDM.Setup.v$version.zip"
    $downloadUrl = "https://github.com/avm3005/detaroxzAutoDM/releases/download/v$version/$zipName"

    Write-Host ""
    Write-Host "Downloading package..." -ForegroundColor Yellow

    # Temp folder
    $tempDir = Join-Path $env:TEMP ("AutoDM_" + [guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    $zipPath = Join-Path $tempDir $zipName

    # Download ZIP
    Invoke-WebRequestWithRetry -Uri $downloadUrl -OutFile $zipPath

    if (!(Test-Path $zipPath)) {
        throw "Download failed."
    }

    Write-Host "Download complete." -ForegroundColor Green

    # Extract ZIP
    Write-Host ""
    Write-Host "Extracting files..." -ForegroundColor Yellow

    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

    Write-Host "Extraction complete." -ForegroundColor Green

    # Find setup.cmd
    $setupCmd = Get-ChildItem -Path $tempDir -Filter "setup.cmd" -Recurse -File | Select-Object -First 1

    if (-not $setupCmd) {
        throw "setup.cmd not found in extracted files."
    }

    Write-Host ""
    Write-Host "Found setup.cmd:" -ForegroundColor Cyan
    Write-Host $setupCmd.FullName -ForegroundColor White

    Write-Host ""
    Write-Host "Launching installer..." -ForegroundColor Green

    # Create BAT launcher
    $launcherBat = Join-Path $tempDir "launch_installer.bat"

    $batContent = @"
@echo off
cd /d "%~dp0"
call "$($setupCmd.FullName)"
pause
"@
    Set-Content -Path $launcherBat -Value $batContent -Encoding ASCII

    # Launch using Windows Terminal if available, otherwise fallback to CMD to prevent crashes
    if (Get-Command "wt.exe" -ErrorAction SilentlyContinue) {
        Start-Process -FilePath "wt.exe" -ArgumentList "cmd.exe /k `"$launcherBat`"" -Verb RunAs
    } else {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/k `"$launcherBat`"" -Verb RunAs
    }

    Write-Host ""
    Write-Host "Installer started successfully." -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "             INSTALL ERROR              " -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
}
