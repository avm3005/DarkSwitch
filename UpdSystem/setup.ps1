$ErrorActionPreference = "Stop"

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "        AutoDM Cloud Installer          " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {

    # Get latest version
    $versionUrl = "https://raw.githubusercontent.com/avm3005/detaroxzAutoDM/main/UpdSystem/version.txt"

    Write-Host "Checking latest version..." -ForegroundColor Yellow

    $versionRaw = (Invoke-WebRequest -Uri $versionUrl -UseBasicParsing).Content.Trim()
    $version = $versionRaw -replace '^v', ''

    Write-Host "Latest Version: v$version" -ForegroundColor Green

    # Build download URL
    $zipName = "AutoDM.Setup.v$version.zip"

    $downloadUrl = "https://github.com/avm3005/detaroxzAutoDM/releases/download/v$version/$zipName"

    Write-Host ""
    Write-Host "Downloading package..." -ForegroundColor Yellow

    # Create temp folder
    $tempDir = Join-Path $env:TEMP ("AutoDM_" + [guid]::NewGuid().ToString())

    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    $zipPath = Join-Path $tempDir $zipName

    # Download
    Invoke-WebRequest `
        -Uri $downloadUrl `
        -OutFile $zipPath `
        -UseBasicParsing

    # Verify
    if (!(Test-Path $zipPath)) {
        throw "Download failed."
    }

    Write-Host "Download complete." -ForegroundColor Green

    # Extract
    Write-Host ""
    Write-Host "Extracting files..." -ForegroundColor Yellow

    Expand-Archive `
        -Path $zipPath `
        -DestinationPath $tempDir `
        -Force

    Write-Host "Extraction complete." -ForegroundColor Green

    # Search setup.cmd recursively
    $setupCmd = Get-ChildItem `
        -Path $tempDir `
        -Filter "setup.cmd" `
        -Recurse `
        -File | Select-Object -First 1

    if (-not $setupCmd) {
        throw "setup.cmd was not found after extraction."
    }

    Write-Host ""
    Write-Host "Found installer:" -ForegroundColor Cyan
    Write-Host $setupCmd.FullName -ForegroundColor White

    Write-Host ""
    Write-Host "Launching AutoDM Installer..." -ForegroundColor Green

    # Create launcher BAT file
    $launcherBat = Join-Path $tempDir "launch_installer.bat"

    @"
@echo off
cd /d "%~dp0"
call "$($setupCmd.FullName)"
pause
"@ | Set-Content -Path $launcherBat -Encoding ASCII

    # Open using modern Windows Terminal
    Start-Process `
        -FilePath "wt.exe" `
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
