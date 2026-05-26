$ErrorActionPreference = "Stop"
Write-Host "Initializing AutoDM Cloud Engine..." -ForegroundColor Cyan

try {
    # 1. Fetch the latest version from the UpdSystem subfolder
    $versionUrl = "https://raw.githubusercontent.com/avm3005/detaroxzAutoDM/main/UpdSystem/version.txt"
    $version = (Invoke-RestMethod -Uri $versionUrl -UseBasicParsing).Trim() -replace '^v', ''
    
    # 2. Construct dynamic URLs
    $zipName = "AutoDM.Setup.v${version}.zip"
    $downloadUrl = "https://github.com/avm3005/detaroxzAutoDM/releases/tag/v${version}/AutoDM.Setup.v1.3.1.zip"
    
    # 3. Create secure temporary directory
    $tempDir = Join-Path $env:TEMP "AutoDM_Install_$([guid]::NewGuid().ToString().Substring(0,8))"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    $zipPath = Join-Path $tempDir $zipName
    
    # 4. Download and Extract
    Write-Host "Downloading AutoDM v${version}..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
    
    Write-Host "Extracting archive..." -ForegroundColor Yellow
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
    
    $setupCmd = Join-Path $tempDir "setup.cmd"
    if (Test-Path $setupCmd) {
        Write-Host "Launching Environment Setup..." -ForegroundColor Green
        # 5. Launch setup.cmd elevated and wait for it to finish
        $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$setupCmd`"" -Verb RunAs -PassThru -WindowStyle Normal
        $proc.WaitForExit()
    } else {
        Write-Host "Error: setup.cmd not found in the downloaded archive." -ForegroundColor Red
    }
    
    # 6. Silent Cleanup
    Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Done!" -ForegroundColor Green

} catch {
    Write-Host "A critical error occurred: $_" -ForegroundColor Red
}
