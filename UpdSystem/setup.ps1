$ErrorActionPreference = "Stop"

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Clear-Host

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "        AutoDM Cloud Installer          " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {

    # Version file
    $versionUrl = "https://raw.githubusercontent.com/avm3005/detaroxzAutoDM/main/UpdSystem/version.txt"

    Write-Host "Checking latest version..." -ForegroundColor Yellow

    $versionRaw = (Invoke-WebRequest -Uri $versionUrl -UseBasicParsing).Content.Trim()
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
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing

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

    # Launch using Windows Terminal
    Start-Process -FilePath "wt.exe" `
        -ArgumentList "cmd.exe /k `"$launcherBat`"" `
        -Verb RunAs

    Write-Host ""
    Write-Host "Installer started successfully." -ForegroundColor Green

}
catch {

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "              INSTALL ERROR             " -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
}
