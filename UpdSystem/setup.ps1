$ErrorActionPreference = "Stop"

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Initializing AutoDM Cloud Engine..." -ForegroundColor Cyan

try {

    # Fetch latest version
    $versionUrl = "https://raw.githubusercontent.com/avm3005/detaroxzAutoDM/main/UpdSystem/version.txt"

    $versionRaw = (Invoke-WebRequest -Uri $versionUrl -UseBasicParsing).Content.Trim()

    # Remove leading v if present
    $version = $versionRaw -replace '^v', ''

    Write-Host "Detected Version: v$version" -ForegroundColor Green

    # ZIP filename
    $zipName = "AutoDM.Setup.v$version.zip"

    # Release download URL
    $downloadUrl = "https://github.com/avm3005/detaroxzAutoDM/releases/download/v$version/$zipName"

    Write-Host "Download URL:" -ForegroundColor DarkGray
    Write-Host $downloadUrl -ForegroundColor Yellow

    # Temp directory
    $tempDir = Join-Path $env:TEMP "AutoDM_Install_$([guid]::NewGuid().ToString().Substring(0,8))"

    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    $zipPath = Join-Path $tempDir $zipName

    # Download ZIP
    Write-Host "Downloading AutoDM v$version..." -ForegroundColor Yellow

    Invoke-WebRequest `
        -Uri $downloadUrl `
        -OutFile $zipPath `
        -UseBasicParsing

    # Validate download
    if (!(Test-Path $zipPath)) {
        throw "ZIP file was not downloaded."
    }

    $fileSize = (Get-Item $zipPath).Length

    Write-Host "Downloaded Size: $fileSize bytes" -ForegroundColor Cyan

    if ($fileSize -lt 1000) {
        throw "Downloaded file is too small and likely invalid."
    }

    # Extract archive
    Write-Host "Extracting archive..." -ForegroundColor Yellow

    Expand-Archive `
        -Path $zipPath `
        -DestinationPath $tempDir `
        -Force

    # Locate setup.cmd
    $setupCmd = Join-Path $tempDir "setup.cmd"

    if (Test-Path $setupCmd) {

        Write-Host "Launching Environment Setup..." -ForegroundColor Green

        $proc = Start-Process `
            -FilePath "cmd.exe" `
            -ArgumentList "/c `"$setupCmd`"" `
            -Verb RunAs `
            -PassThru `
            -WindowStyle Normal

        $proc.WaitForExit()

    } else {

        throw "setup.cmd not found in extracted files."
    }

    # Cleanup
    Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan

    Remove-Item `
        -Path $tempDir `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue

    Write-Host "Done!" -ForegroundColor Green

}
catch {

    Write-Host ""
    Write-Host "A critical error occurred:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
