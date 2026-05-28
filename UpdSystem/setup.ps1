$ErrorActionPreference = "Stop"

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

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempDir)

    Write-Host "Extraction completed successfully." -ForegroundColor Green

    # Locate setup.cmd recursively
    $setupCmd = Get-ChildItem -Path $tempDir -Filter "setup.cmd" -Recurse | Select-Object -First 1

    if ($setupCmd) {

        Write-Host "Launching Environment Setup..." -ForegroundColor Green
        Write-Host "Found setup.cmd at:" -ForegroundColor Cyan
        Write-Host $setupCmd.FullName -ForegroundColor Yellow

        # Use cmd.exe start command through Windows Terminal
        # This fully fixes path parsing issues
        Start-Process `
            -FilePath "wt.exe" `
            -ArgumentList "cmd.exe /k cd /d `"$($setupCmd.DirectoryName)`" && call `"$($setupCmd.FullName)`"" `
            -Verb RunAs

    } else {

        throw "setup.cmd not found in extracted files."
    }

    Write-Host "Installer launched successfully." -ForegroundColor Green

}
catch {

    Write-Host ""
    Write-Host "A critical error occurred:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
