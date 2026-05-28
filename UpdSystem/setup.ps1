$ErrorActionPreference = "Stop"

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Initializing AutoDM Cloud Engine..." -ForegroundColor Cyan

try {

    # Fetch latest version
    $versionUrl = "https://raw.githubusercontent.com/avm3005/detaroxzAutoDM/main/UpdSystem/version.txt"

    $versionRaw = (Invoke-WebRequest -Uri $versionUrl -UseBasicParsing).Content.Trim()

    # Remove leading 'v' if present
    $version = $versionRaw -replace '^v', ''

    Write-Host "Detected Version: v$version" -ForegroundColor Green

    # ZIP filename
    $zipName = "AutoDM.Setup.v$version.zip"

    # Release download URL
    $downloadUrl = "https://github.com/avm3005/detaroxzAutoDM/releases/download/v$version/$zipName"

    Write-Host "Download URL:" -ForegroundColor DarkGray
    Write-Host $downloadUrl -ForegroundColor Yellow

    # Create temporary directory
    $tempDir = Join-Path $env:TEMP "AutoDM_Install_$([guid]::NewGuid().ToString().Substring(0,8))"

    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    $zipPath = Join-Path $tempDir $zipName

    # Download ZIP
    Write-Host "Downloading AutoDM v$version..." -ForegroundColor Yellow

    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "Mozilla/5.0")

    $webClient.DownloadFile($downloadUrl, $zipPath)

    # Validate download
    if (!(Test-Path $zipPath)) {
        throw "ZIP file was not downloaded."
    }

    $fileSize = (Get-Item $zipPath).Length

    Write-Host "Downloaded Size: $fileSize bytes" -ForegroundColor Cyan

    if ($fileSize -lt 1000) {
        throw "Downloaded file is too small and likely invalid."
    }

    # Validate ZIP signature
    $signature = Get-Content -Path $zipPath -Encoding Byte -TotalCount 4

    if (
        $signature[0] -ne 0x50 -or
        $signature[1] -ne 0x4B
    ) {
        throw "Downloaded file is not a valid ZIP archive."
    }

    # Extract archive
    Write-Host "Extracting archive..." -ForegroundColor Yellow

    # Use .NET extraction instead of Expand-Archive for better compatibility
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempDir)

    Write-Host "Extraction completed successfully." -ForegroundColor Green

    # Locate setup.cmd
    $setupCmd = Join-Path $tempDir "setup.cmd"

    if (Test-Path $setupCmd) {

        Write-Host "Launching Environment Setup..." -ForegroundColor Green

        # Launch in modern Windows 11 Terminal
        $proc = Start-Process `
            -FilePath "wt.exe" `
            -ArgumentList "cmd /k `"$setupCmd`"" `
            -Verb RunAs `
            -PassThru

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
