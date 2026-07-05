# --- POWERSHELL NATIVE ENGINE ---
# Self-Elevate to Administrator (Optimized for instant launch)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $hasWT = (Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe") -or [bool](Get-Item "$env:windir\System32\wt.exe" -ErrorAction SilentlyContinue)
    if ($hasWT) {
        Start-Process wt.exe -Verb RunAs -ArgumentList "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    }
    exit
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$e = [char]27
$cMain = "$e[38;5;51m"
$cAccent = "$e[38;5;213m"
$cText = "$e[97m"
$cDim = "$e[90m"
$cGreen = "$e[38;5;46m"
$cRed = "$e[38;5;196m"
$cYellow = "$e[38;5;226m"
$cReset = "$e[0m"

# --- VBSCRIPT DEPENDENCY CHECK ---
$vbsDll = "$env:windir\System32\vbscript.dll"
if (-not (Test-Path $vbsDll)) {
    Clear-Host
    Write-Host "$cMain===========================================================================$cReset"
    Write-Host " $cAccent REQUIRED COMPONENT MISSING: VBScript$cReset"
    Write-Host "$cMain===========================================================================$cReset`n"
    Write-Host "  Starting with Windows 11 24H2, Microsoft has made VBScript an 'Optional Feature'" -ForegroundColor Yellow
    Write-Host "  and disabled it by default on new installations." -ForegroundColor Yellow
    Write-Host "`n  $e[1;32m[WHY DARKSWITCH NEEDS THIS]$e[0m" -ForegroundColor Green
    Write-Host "  Dark Switch uses a tiny, native VBScript engine to switch your theme seamlessly in the" -ForegroundColor Green
    Write-Host "  background. Without it, a black console window will abruptly 'flash' on your" -ForegroundColor Green
    Write-Host "  screen every time your theme changes or your PC boots." -ForegroundColor Green
    Write-Host "`n  $cMain> The setup can automatically download and install VBScript via DISM.$cReset"
    Write-Host "  (This uses official Microsoft servers and may take a minute or two)" -ForegroundColor DarkGray
    
    $vbsChoice = Read-Host "`n  -> Do you want to install VBScript and proceed? (Y/N) [Default: N]"
    if ($vbsChoice -match '^[Yy]') {
        Write-Host "`n  [+] Interfacing with DISM... Downloading and enabling VBScript..." -ForegroundColor Cyan
        try {
            Get-WindowsCapability -Online -Name "VBScript*" | Add-WindowsCapability -Online -ErrorAction Stop | Out-Null
            if (Test-Path $vbsDll) {
                Write-Host "  [+] VBScript successfully installed! Resuming setup...`n" -ForegroundColor Green
                Start-Sleep -Seconds 2
            } else {
                Write-Host "  [!] Failed to verify VBScript installation. Setup cannot continue." -ForegroundColor Red
                Start-Sleep -Seconds 3
                exit 1
            }
        } catch {
            Write-Host "  [!] Error installing VBScript: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "  Make sure you are connected to the internet and Windows Update is running." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
            exit 1
        }
    } else {
        Write-Host "`n  [!] Setup aborted. VBScript is required for Dark Switch to function seamlessly." -ForegroundColor Red
        Start-Sleep -Seconds 3
        exit 1
    }
}

# [TAMPER VERIFIER - DO NOT MODIFY THESE STRINGS OR THE SETUP WILL CRASH]
$devName = "detaroxz"
$devLink = "https://github.com/avm3005/"
$projectLink = "https://github.com/avm3005/detaroxzDarkSwitch"
$devWebsite = "https://avm3005.github.io/portfolio/"
$moreProjectsLink = "https://github.com/avm3005?tab=repositories"
$appVersion = "1.5.1"
if ([System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("ZGV0YXJveHo=")) -cne $devName -or [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("aHR0cHM6Ly9naXRodWIuY29tL2F2bTMwMDUv")) -cne $devLink) { exit 1 }

$targetDir = "C:\Program Files\Detaroxz\DarkSwitch"
$isUpdate = Test-Path $targetDir

$installedVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\DarkSwitch" -Name "DisplayVersion" -ErrorAction SilentlyContinue).DisplayVersion

$modeText = "Installing (v$appVersion)"
if ($isUpdate) {
    if ($installedVersion -eq $appVersion) {
        $modeText = "Reinstalling (v$appVersion)"
    } elseif ($installedVersion) {
        $modeText = "Updating (from v$installedVersion to v$appVersion)"
    } else {
        $modeText = "Updating (from older version to v$appVersion)"
    }
}

Clear-Host
Write-Host "$cMain===========================================================================$cReset"
Write-Host " $cAccent DARK SWITCH SETUP ENGINE$cReset"
Write-Host " $cDim Crafted by $devName  |  Mode: $modeText$cReset"
Write-Host "$cMain===========================================================================$cReset`n"

if ($isUpdate) {
    Write-Host "  $cYellow-> Existing installation detected. Initializing sequence...$cReset`n"
}

# TIME FORMAT DETECTION
$is24Hour = (Get-Culture).DateTimeFormat.ShortTimePattern -cmatch 'H'
$timeFormat = if ($is24Hour) { "HH:mm" } else { "h:mm tt" }
$timeHint = if ($is24Hour) { "HH:MM (e.g., 07:00, 19:30)" } else { "HH:MM AM/PM (e.g., 7:00 AM, 7:30 PM)" }

Write-Host "$e[3mDetected Time Format: $timeHint$e[0m"
Write-Host "$e[90mPress ENTER without typing anything to use the defaults.$e[0m`n"

function Get-ValidTime ($Prompt, $Default) {
    while ($true) {
        $timeStr = Read-Host "$Prompt [Default: $Default]"
        if ([string]::IsNullOrWhiteSpace($timeStr)) { return $Default }
        try { return [datetime]::Parse($timeStr).ToString($timeFormat) } 
        catch { Write-Host "  -> Invalid format. Use $timeHint.`n" -ForegroundColor Red }
    }
}

# --- DIRECTORY PATHS ---
$engineDir = "$targetDir\Engine"
$resourceDir = "$targetDir\Resources"
$wpDir = "$targetDir\Wallpapers"
$startMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\DarkSwitch"
$legacyStartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\DarkSwitch"
$tPath = "\Detaroxz\DarkSwitch\"

$coreEnginePath = "$engineDir\CoreEngine.ps1"
$vbsRunnerPath = "$engineDir\RunSilent.vbs"
$configPath = "$targetDir\config.ini"
$dllPath = "$engineDir\DarkSwitchEngine.dll"

$psSettingsPath = "$targetDir\DarkSwitch-Core.ps1"
$psUninstallPath = "$targetDir\Uninstall.ps1"
$uninstallRegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\DarkSwitch"
$regDarkSwitch = "HKCU:\SOFTWARE\DarkSwitch"

# --- SMART IMPORT LOGIC & BACKUPS ---
$defLight = if ($is24Hour) { "07:00" } else { "7:00 AM" }
$defDark = if ($is24Hour) { "19:00" } else { "7:00 PM" }
$defSun1 = if ($is24Hour) { "00:00" } else { "12:00 AM" }

$config = @{}

if (Test-Path $configPath) {
    Write-Host "  -> Config file detected. Importing settings...`n" -ForegroundColor Yellow
    try {
        Get-Content $configPath -ErrorAction Stop | ForEach-Object {
            if ($_ -match "^(.*?)=(.*)$") { $config[$matches[1].Trim()] = $matches[2].Trim() }
        }
    } catch {
        Write-Host "  [!] Failed to read config file. Proceeding with safe defaults.`n" -ForegroundColor Red
    }
}

# 1. METHOD OF SWITCH & TIME CONFIGURATION
try {
    if (-not $config.ContainsKey("DynamicSun") -or [string]::IsNullOrWhiteSpace($config["DynamicSun"])) { throw "Missing" }
    $dynSun = $config["DynamicSun"]
    $sunTime = if ($config.ContainsKey("SunTime")) { $config["SunTime"] } else { $defSun1 }
    $sunSyncBoot = if ($config.ContainsKey("SunSyncBoot")) { $config["SunSyncBoot"] } else { "Y" }
    $lightTime = $config["LightTime"]
    $darkTime = $config["DarkTime"]
    
    $modeDisplay = if ($dynSun -eq "Y") { "Dynamic Sunrise/Sunset" } else { "Scheduled" }
    Write-Host "  [+] Kept Method of Switch    : $e[36m$modeDisplay$e[0m"
    if ($dynSun -eq "N") {
        if ([string]::IsNullOrWhiteSpace($lightTime)) { $lightTime = $defLight }
        if ([string]::IsNullOrWhiteSpace($darkTime)) { $darkTime = $defDark }
        Write-Host "  [+] Kept Light Mode Time     : $e[36m$lightTime$e[0m"
        Write-Host "  [+] Kept Dark Mode Time      : $e[36m$darkTime$e[0m"
    }
} catch {
    $defLToUse = if (-not [string]::IsNullOrWhiteSpace($config["LightTime"])) { $config["LightTime"] } else { $defLight }
    $defDToUse = if (-not [string]::IsNullOrWhiteSpace($config["DarkTime"])) { $config["DarkTime"] } else { $defDark }

    Write-Host "  -> Select Method of Switch:" -ForegroundColor Cyan
    Write-Host "      [1] Scheduled (Fixed Time) [Default]"
    Write-Host "      [2] Dynamic Sunrise/Sunset Sync (Requires Location)"
    $modeChoice = Read-Host "  -> Enter 1 or 2"
    
    if ($modeChoice -eq "2") {
        # Consent Check in Setup
        Write-Host "`n  $cAccent[LOCATION ACCESS CONSENT REQUIRED]$cReset"
        Write-Host "  Dark Switch needs to access your device location using the Windows Location API" -ForegroundColor Yellow
        Write-Host "  to automatically compute precise, local sunrise and sunset times daily." -ForegroundColor Yellow
        Write-Host "  $e[1;32m[OFFLINE COMPLIANCE]$e[0m This process is 100% OFFLINE." -ForegroundColor Green
        Write-Host "  Your coordinates are fetched and kept locally. Nothing is ever sent over the internet." -ForegroundColor Green

        $consentChoice = Read-Host "`n  -> Do you consent to allow location access? (Y/N) [Default: N]"
        if ($consentChoice -match '^[Yy]') {
            $config["LocationConsent"] = "Y"
            Write-Host "`n  -> Consent granted. Fetching location (this may take up to 15s) " -ForegroundColor Yellow -NoNewline
            Add-Type -AssemblyName System.Device -ErrorAction SilentlyContinue
            $lat = $null; $lon = $null
            try {
                $watcher = New-Object System.Device.Location.GeoCoordinateWatcher([System.Device.Location.GeoPositionAccuracy]::High)
                $watcher.Start()
                $timeout = 15
                while (($watcher.Status -ne 'Ready' -or $watcher.Position.Location.IsUnknown) -and ($timeout -gt 0)) { 
                    Write-Host "." -ForegroundColor Yellow -NoNewline
                    Start-Sleep -Seconds 1
                    $timeout-- 
                }
                Write-Host ""
                if (-not $watcher.Position.Location.IsUnknown) {
                    $lat = $watcher.Position.Location.Latitude
                    $lon = $watcher.Position.Location.Longitude
                } else {
                    Write-Host "`n  [!] Auto-fetch failed (No GPS/Wi-Fi info). Falling back to manual entry." -ForegroundColor Yellow
                    Write-Host "  -> You can find your coordinates by right-clicking your location on Google Maps." -ForegroundColor DarkGray
                    $latIn = Read-Host "  -> Enter Latitude  (e.g. 40.7128)"
                    $lonIn = Read-Host "  -> Enter Longitude (e.g. -74.0060)"
                    try {
                        $lat = [double]::Parse(($latIn -replace ',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
                        $lon = [double]::Parse(($lonIn -replace ',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
                    } catch { $lat = $null; $lon = $null }
                }
                $watcher.Stop()
            } catch {}
            
            if ($null -ne $lat -and $null -ne $lon) {
                Write-Host "  -> Location successfully acquired!" -ForegroundColor Green
                $dynSun = "Y"
                $config["LastLat"] = $lat.ToString([System.Globalization.CultureInfo]::InvariantCulture)
                $config["LastLon"] = $lon.ToString([System.Globalization.CultureInfo]::InvariantCulture)
                
                $sunTime = Get-ValidTime "Enter time to perform daily calculation" $defSun1
                $config["SunTime"] = $sunTime

                $bootChoice = Read-Host "Sync Sunrise/Sunset times on Boot? (Y/N) [Default: Y]"
                $sunSyncBoot = if ($bootChoice -match '^[Nn]') { "N" } else { "Y" }
                $config["SunSyncBoot"] = $sunSyncBoot
                
                $lightTime = $defLToUse; $darkTime = $defDToUse # Auto-corrected later
            } else {
                Write-Host "  [!] Location fetching is not possible on this device. Falling back to scheduled mode." -ForegroundColor Red
                $dynSun = "N"
                $sunSyncBoot = "N"
                $lightTime = Get-ValidTime "Enter LIGHT mode time" $defLToUse
                $darkTime = Get-ValidTime "Enter DARK mode time" $defDToUse
            }
        } else {
            Write-Host "`n  [!] Consent denied. Falling back to Scheduled Mode (Fixed Time)." -ForegroundColor Red
            $dynSun = "N"
            $sunSyncBoot = "Y"
            $lightTime = Get-ValidTime "Enter LIGHT mode time" $defLToUse
            $darkTime = Get-ValidTime "Enter DARK mode time" $defDToUse
        }
    } else {
        $dynSun = "N"
        $sunSyncBoot = "Y"
        $lightTime = Get-ValidTime "Enter LIGHT mode time" $defLToUse
        $darkTime = Get-ValidTime "Enter DARK mode time" $defDToUse
    }
    $config["DynamicSun"] = $dynSun
    $config["LightTime"] = $lightTime
    $config["DarkTime"] = $darkTime
    $config["SunSyncBoot"] = $sunSyncBoot
}

# 3. BOOT SYNC
try {
    if (-not $config.ContainsKey("BootSync") -or [string]::IsNullOrWhiteSpace($config["BootSync"])) { throw "Missing" }
    $enableBoot = $config["BootSync"]
    if ($enableBoot -notmatch '^[YyNn]') { throw "Invalid" }
    Write-Host "  [+] Kept Boot Sync State     : $e[36m$enableBoot$e[0m"
} catch {
    $enableBoot = Read-Host "Enable 'Trigger on boot' (Log-on & Wake Sync)? (Y/N) [Default: Y]"
    if ([string]::IsNullOrWhiteSpace($enableBoot)) { $enableBoot = "Y" }
    $config["BootSync"] = $enableBoot
}

# 4. SHORTCUT TOGGLE
try {
    if (-not $config.ContainsKey("Shortcut") -or [string]::IsNullOrWhiteSpace($config["Shortcut"])) { throw "Missing" }
    $enableShortcut = $config["Shortcut"]
    if ($enableShortcut -notmatch '^[YyNn]') { throw "Invalid" }
    Write-Host "  [+] Kept Quick Toggle        : $e[36m$enableShortcut$e[0m"
} catch {
    $enableShortcut = Read-Host "Enable Quick Toggle Keyboard Shortcut? (Y/N) [Default: Y]"
    if ([string]::IsNullOrWhiteSpace($enableShortcut)) { $enableShortcut = "Y" }
    $config["Shortcut"] = $enableShortcut
}

# 5. SHORTCUT KEY
try {
    if (-not $config.ContainsKey("ShortcutKey") -or [string]::IsNullOrWhiteSpace($config["ShortcutKey"])) { throw "Missing" }
    $shortcutKey = $config["ShortcutKey"]
    Write-Host "  -> Quick Toggle Shortcut is set to Ctrl+Alt+$shortcutKey.`n" -ForegroundColor Cyan
} catch {
    $shortcutKey = "T"
    $config["ShortcutKey"] = $shortcutKey
    Write-Host "  -> Quick Toggle Shortcut is set to Ctrl+Alt+$shortcutKey.`n" -ForegroundColor Cyan
}

# 6. WALLPAPER ENGINE
$hasWp = $false
try {
    if (-not $config.ContainsKey("WallpaperEnabled") -or [string]::IsNullOrWhiteSpace($config["WallpaperEnabled"])) { throw "Missing" }
    $wpEnabled = [int]$config["WallpaperEnabled"]
    Write-Host "  [+] Kept Wallpaper Settings  : $e[36m$(if($wpEnabled -eq 1){'Y'}else{'N'})$e[0m"
    $hasWp = $true
} catch {
    $inWp = Read-Host "Enable Environment Wallpaper Switch? (Y/N) [Default: N]"
    $wpEnabled = if ($inWp -match '^[Yy]') { 1 } else { 0 }
    $config["WallpaperEnabled"] = $wpEnabled
}

# 7. ACCENT ENGINE
$hasAcc = $false
try {
    if (-not $config.ContainsKey("AccentEnabled") -or [string]::IsNullOrWhiteSpace($config["AccentEnabled"])) { throw "Missing" }
    $accEnabled = [int]$config["AccentEnabled"]
    Write-Host "  [+] Kept Accent Col Settings : $e[36m$(if($accEnabled -eq 1){'Y'}else{'N'})$e[0m"
    $hasAcc = $true
} catch {
    $inAcc = Read-Host "Enable Environment Accent Color Switch? (Y/N) [Default: N]"
    $accEnabled = if ($inAcc -match '^[Yy]') { 1 } else { 0 }
    $config["AccentEnabled"] = $accEnabled
}

function Invoke-Rollback {
    Write-Host "`n$e[1;31m[!] A fatal error occurred. Initiating rollback...$e[0m"
    Get-ScheduledTask -TaskName "DarkSwitch*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "DarkSwitch" -ErrorAction SilentlyContinue
    if (Test-Path $startMenuPath) { Remove-Item -Path $startMenuPath -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $legacyStartMenuPath) { Remove-Item -Path $legacyStartMenuPath -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $uninstallRegKey) { Remove-Item -Path $uninstallRegKey -Force -Recurse -ErrorAction SilentlyContinue }
    if (Test-Path $regDarkSwitch) { Remove-Item $regDarkSwitch -Force -Recurse -ErrorAction SilentlyContinue }
    if (Test-Path $targetDir) { Start-Process powershell -ArgumentList "-WindowStyle Hidden -Command `"Start-Sleep -Seconds 2; Remove-Item -Path '$targetDir' -Recurse -Force -ErrorAction SilentlyContinue`"" }
    Write-Host "$e[31mRollback complete.$e[0m"
    Write-Host "`nPress ENTER to exit..." -ForegroundColor Yellow
    Read-Host
    exit 1
}

function Set-TaskPriority {
    param($TaskName, $Priority)
    $xml = try { Export-ScheduledTask -TaskName $TaskName -TaskPath $tPath -ErrorAction Stop | Out-String } catch { $null }
    if ($xml) {
        if ($xml -match '<Priority>\s*\d+\s*</Priority>') {
            $xml = $xml -replace '<Priority>\s*\d+\s*</Priority>', "<Priority>$Priority</Priority>"
        } else {
            $xml = $xml -replace '</Settings>', "  <Priority>$Priority</Priority>`n  </Settings>"
        }
        try { Register-ScheduledTask -TaskName $TaskName -TaskPath $tPath -Xml $xml -Force -User $env:USERNAME -ErrorAction Stop | Out-Null } catch {}
    }
}

$ErrorActionPreference = "Stop"

try {
    Write-Host "`n$e[36m[1/9] Preparing installation directories...$e[0m"
    
    if ($isUpdate) {
        Write-Host "  -> Closing any open Dark Switch core window..." -ForegroundColor Yellow
    }
    Get-ScheduledTask -TaskName "DarkSwitch*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
    try {
        $procs = Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='cmd.exe' OR Name='wscript.exe'"
        foreach ($p in $procs) {
            if ($p.CommandLine -match "DarkSwitch" -and $p.ProcessId -ne $PID) {
                Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}
    Start-Sleep -Milliseconds 500

    $tempBackup = $null
    if (Test-Path -Path $targetDir) {
        $tempBackup = "C:\Program Files\Detaroxz\temp"
        if (Test-Path $tempBackup) { Remove-Item $tempBackup -Recurse -Force | Out-Null }
        New-Item -ItemType Directory -Path $tempBackup -Force | Out-Null
        
        if (Test-Path $configPath) {
            Write-Host "  -> Backing up config..." -ForegroundColor Yellow
            Copy-Item $configPath "$tempBackup\" -Force | Out-Null 
        }
        
        if (Test-Path $wpDir) {
            Write-Host "  -> Backing up wallpapers..." -ForegroundColor Yellow
            New-Item -ItemType Directory -Path "$tempBackup\Wallpapers" -Force | Out-Null
            Copy-Item "$wpDir\*" "$tempBackup\Wallpapers\" -Recurse -Force | Out-Null
        }
        
        Write-Host "  -> Cleaning up old files natively (preventing uninstaller conflicts)..." -ForegroundColor Yellow
        Get-ChildItem -Path $targetDir | Where-Object { $_.FullName -ne $tempBackup } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "DarkSwitch" -ErrorAction SilentlyContinue
    if (Test-Path $legacyStartMenuPath) { Remove-Item -Path $legacyStartMenuPath -Recurse -Force -ErrorAction SilentlyContinue }
    
    if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
    if (-not (Test-Path $engineDir)) { New-Item -ItemType Directory -Path $engineDir -Force | Out-Null }
    if (-not (Test-Path $resourceDir)) { New-Item -ItemType Directory -Path $resourceDir -Force | Out-Null }
    if (-not (Test-Path $wpDir)) { New-Item -ItemType Directory -Path $wpDir -Force | Out-Null }
    if (-not (Test-Path -Path $startMenuPath)) { New-Item -ItemType Directory -Path $startMenuPath -Force | Out-Null }

    # Setup core Registry values with default Settings
    if (-not (Test-Path $regDarkSwitch)) { New-Item $regDarkSwitch -Force | Out-Null }
    Set-ItemProperty -Path $regDarkSwitch -Name "ShortcutKey" -Value $shortcutKey -Force
    Set-ItemProperty -Path $regDarkSwitch -Name "WallpaperEnabled" -Value $wpEnabled -Type DWord -Force
    Set-ItemProperty -Path $regDarkSwitch -Name "AccentEnabled" -Value $accEnabled -Type DWord -Force
    Set-ItemProperty -Path $regDarkSwitch -Name "DynamicSun" -Value $dynSun -Force
    Set-ItemProperty -Path $regDarkSwitch -Name "TopNavEnabled" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $regDarkSwitch -Name "UpdateMenuEnabled" -Value 1 -Type DWord -Force
    if ($config.ContainsKey("LocationConsent")) { Set-ItemProperty -Path $regDarkSwitch -Name "LocationConsent" -Value $config["LocationConsent"] -Force }
    if ($config.ContainsKey("SunTime")) { Set-ItemProperty -Path $regDarkSwitch -Name "SunTime" -Value $config["SunTime"] -Force }
    if ($config.ContainsKey("SunSyncBoot")) { Set-ItemProperty -Path $regDarkSwitch -Name "SunSyncBoot" -Value $config["SunSyncBoot"] -Force }
    if ($config.ContainsKey("LightTime")) { Set-ItemProperty -Path $regDarkSwitch -Name "LightTime" -Value $config["LightTime"] -Force }
    if ($config.ContainsKey("DarkTime")) { Set-ItemProperty -Path $regDarkSwitch -Name "DarkTime" -Value $config["DarkTime"] -Force }
    if ($config.ContainsKey("LastLat")) { Set-ItemProperty -Path $regDarkSwitch -Name "LastLat" -Value $config["LastLat"] -Force }
    if ($config.ContainsKey("LastLon")) { Set-ItemProperty -Path $regDarkSwitch -Name "LastLon" -Value $config["LastLon"] -Force }
    
    if ($config.ContainsKey("LightWpMode")) { Set-ItemProperty -Path $regDarkSwitch -Name "LightWpMode" -Value $config["LightWpMode"] -Type DWord -Force }
    if ($config.ContainsKey("DarkWpMode")) { Set-ItemProperty -Path $regDarkSwitch -Name "DarkWpMode" -Value $config["DarkWpMode"] -Type DWord -Force }
    if ($config.ContainsKey("LightWpFile")) { Set-ItemProperty -Path $regDarkSwitch -Name "LightWpFile" -Value $config["LightWpFile"] -Force }
    if ($config.ContainsKey("DarkWpFile")) { Set-ItemProperty -Path $regDarkSwitch -Name "DarkWpFile" -Value $config["DarkWpFile"] -Force }
    if ($config.ContainsKey("LightWpColor")) { Set-ItemProperty -Path $regDarkSwitch -Name "LightWpColor" -Value $config["LightWpColor"] -Force }
    if ($config.ContainsKey("DarkWpColor")) { Set-ItemProperty -Path $regDarkSwitch -Name "DarkWpColor" -Value $config["DarkWpColor"] -Force }
    if ($config.ContainsKey("LightWpFolder")) { Set-ItemProperty -Path $regDarkSwitch -Name "LightWpFolder" -Value $config["LightWpFolder"] -Force }
    if ($config.ContainsKey("DarkWpFolder")) { Set-ItemProperty -Path $regDarkSwitch -Name "DarkWpFolder" -Value $config["DarkWpFolder"] -Force }
    if ($config.ContainsKey("LightWpInterval")) { Set-ItemProperty -Path $regDarkSwitch -Name "LightWpInterval" -Value $config["LightWpInterval"] -Type DWord -Force }
    if ($config.ContainsKey("DarkWpInterval")) { Set-ItemProperty -Path $regDarkSwitch -Name "DarkWpInterval" -Value $config["DarkWpInterval"] -Type DWord -Force }
    
    if ($config.ContainsKey("LightAccMode")) { Set-ItemProperty -Path $regDarkSwitch -Name "LightAccMode" -Value $config["LightAccMode"] -Type DWord -Force }
    if ($config.ContainsKey("DarkAccMode")) { Set-ItemProperty -Path $regDarkSwitch -Name "DarkAccMode" -Value $config["DarkAccMode"] -Type DWord -Force }
    if ($config.ContainsKey("LightAccWinColor")) { Set-ItemProperty -Path $regDarkSwitch -Name "LightAccWinColor" -Value $config["LightAccWinColor"] -Force }
    if ($config.ContainsKey("DarkAccWinColor")) { Set-ItemProperty -Path $regDarkSwitch -Name "DarkAccWinColor" -Value $config["DarkAccWinColor"] -Force }
    if ($config.ContainsKey("LightAccCustom")) { Set-ItemProperty -Path $regDarkSwitch -Name "LightAccCustom" -Value $config["LightAccCustom"] -Force }
    if ($config.ContainsKey("DarkAccCustom")) { Set-ItemProperty -Path $regDarkSwitch -Name "DarkAccCustom" -Value $config["DarkAccCustom"] -Force }
    if ($config.ContainsKey("LightAccent")) { Set-ItemProperty -Path $regDarkSwitch -Name "LightAccent" -Value $config["LightAccent"] -Force }
    if ($config.ContainsKey("DarkAccent")) { Set-ItemProperty -Path $regDarkSwitch -Name "DarkAccent" -Value $config["DarkAccent"] -Force }
    if ($config.ContainsKey("TopNavEnabled")) { Set-ItemProperty -Path $regDarkSwitch -Name "TopNavEnabled" -Value $config["TopNavEnabled"] -Type DWord -Force }
    if ($config.ContainsKey("UpdateMenuEnabled")) { Set-ItemProperty -Path $regDarkSwitch -Name "UpdateMenuEnabled" -Value $config["UpdateMenuEnabled"] -Type DWord -Force }

    # Setup Cursor configuration
    if ($config.ContainsKey("CursorEnabled")) { Set-ItemProperty -Path $regDarkSwitch -Name "CursorEnabled" -Value $config["CursorEnabled"] -Type DWord -Force } else { Set-ItemProperty -Path $regDarkSwitch -Name "CursorEnabled" -Value 0 -Type DWord -Force }
    if ($config.ContainsKey("LightCursor")) { Set-ItemProperty -Path $regDarkSwitch -Name "LightCursor" -Value $config["LightCursor"] -Force } else { Set-ItemProperty -Path $regDarkSwitch -Name "LightCursor" -Value "Windows Default" -Force }
    if ($config.ContainsKey("DarkCursor")) { Set-ItemProperty -Path $regDarkSwitch -Name "DarkCursor" -Value $config["DarkCursor"] -Force } else { Set-ItemProperty -Path $regDarkSwitch -Name "DarkCursor" -Value "Windows Default" -Force }

    # Safely Write The New Config File Out
    try {
        $outData = @()
        foreach ($key in $config.Keys) { $outData += "$key=$($config[$key])" }
        $outData | Set-Content $configPath -Force
    } catch {
        Write-Host "  [!] Warning: Failed to write initial config.ini" -ForegroundColor Red
    }

    if ($tempBackup -and (Test-Path $tempBackup)) {
        if (Test-Path "$tempBackup\config.ini") {
            Copy-Item "$tempBackup\config.ini" $targetDir -Force | Out-Null
        }
        if (Test-Path "$tempBackup\Wallpapers") {
            Copy-Item "$tempBackup\Wallpapers\*" "$wpDir\" -Recurse -Force | Out-Null
        }
        Remove-Item $tempBackup -Recurse -Force | Out-Null
    }

    # Clean old engine files, including the .dll if upgrading
    Get-ChildItem -Path $targetDir -Filter "*.cmd" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $targetDir -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $targetDir -Filter "*.vbs" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $targetDir -Filter "*.dll" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $targetDir -Filter "Toggle.ps1" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

    $currentDirectory = Split-Path $PSCommandPath
    $sourceResources = Join-Path $currentDirectory "Resources"
    
    if (Test-Path $sourceResources) { Copy-Item -Path "$sourceResources\*" -Destination $resourceDir -Recurse -Force } 
    else { Write-Host "$e[33m  -> Warning: Local 'Resources' folder not found. Icons skipped.$e[0m"; $ErrorActionPreference = "Stop" }

    # Setup Initial Backups if Enabled Fresh
    if ($wpEnabled -eq 1 -and -not $hasWp) {
        $bgType = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers' -Name BackgroundType -ErrorAction SilentlyContinue).BackgroundType
        if ($null -eq $bgType) { $bgType = 0 }
        
        Set-ItemProperty -Path $regDarkSwitch -Name "BackupWpMode" -Value $bgType -Type DWord -Force
        Set-ItemProperty -Path $regDarkSwitch -Name "LightWpMode" -Value $bgType -Type DWord -Force
        Set-ItemProperty -Path $regDarkSwitch -Name "DarkWpMode" -Value $bgType -Type DWord -Force
        $config["LightWpMode"] = $bgType
        $config["DarkWpMode"] = $bgType

        # Mode 0 Backup
        $curWp = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallPaper -ErrorAction SilentlyContinue).WallPaper
        if ($curWp -and (Test-Path $curWp)) {
            $ext = [System.IO.Path]::GetExtension($curWp)
            $backupWp = "$wpDir\Default_WP$ext"
            if ($curWp -ne $backupWp) { Copy-Item $curWp $backupWp -Force }
            Set-ItemProperty -Path $regDarkSwitch -Name "BackupWpFile" -Value $backupWp -Force
            Set-ItemProperty -Path $regDarkSwitch -Name "LightWpFile" -Value $backupWp -Force
            Set-ItemProperty -Path $regDarkSwitch -Name "DarkWpFile" -Value $backupWp -Force
            $config["LightWpFile"] = $backupWp; $config["DarkWpFile"] = $backupWp
        }
        
        # Mode 1 Backup
        $curCol = (Get-ItemProperty 'HKCU:\Control Panel\Colors' -Name Background -ErrorAction SilentlyContinue).Background
        if ($curCol) {
            try {
                $parts = $curCol -split ' '
                $hexCol = "#{0:X2}{1:X2}{2:X2}" -f [int]$parts[0], [int]$parts[1], [int]$parts[2]
            } catch { $hexCol = "#000000" }
        } else { $hexCol = "#000000" }
        Set-ItemProperty -Path $regDarkSwitch -Name "BackupWpColor" -Value $hexCol -Force
        Set-ItemProperty -Path $regDarkSwitch -Name "LightWpColor" -Value $hexCol -Force
        Set-ItemProperty -Path $regDarkSwitch -Name "DarkWpColor" -Value $hexCol -Force
        $config["LightWpColor"] = $hexCol; $config["DarkWpColor"] = $hexCol
        
        # Mode 2 Backup
        $curFold = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers' -Name SlideshowDirectoryPath1 -ErrorAction SilentlyContinue).SlideshowDirectoryPath1
        if (-not $curFold) { $curFold = "" }
        $curTick = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers' -Name SlideshowTick -ErrorAction SilentlyContinue).SlideshowTick
        if (-not $curTick) { $curTick = 600000 }
        
        Set-ItemProperty -Path $regDarkSwitch -Name "BackupWpFolder" -Value $curFold -Force
        Set-ItemProperty -Path $regDarkSwitch -Name "LightWpFolder" -Value $curFold -Force
        Set-ItemProperty -Path $regDarkSwitch -Name "DarkWpFolder" -Value $curFold -Force
        Set-ItemProperty -Path $regDarkSwitch -Name "BackupWpInterval" -Value $curTick -Type DWord -Force
        Set-ItemProperty -Path $regDarkSwitch -Name "LightWpInterval" -Value $curTick -Type DWord -Force
        Set-ItemProperty -Path $regDarkSwitch -Name "DarkWpInterval" -Value $curTick -Type DWord -Force
        $config["LightWpFolder"] = $curFold; $config["DarkWpFolder"] = $curFold
        $config["LightWpInterval"] = $curTick; $config["DarkWpInterval"] = $curTick
        
        try {
            $outData = @()
            foreach ($key in $config.Keys) { $outData += "$key=$($config[$key])" }
            $outData | Set-Content $configPath -Force
        } catch {}
    }
    
    if ($accEnabled -eq 1 -and -not $hasAcc) {
        $curAuto = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name AutoColorization -ErrorAction SilentlyContinue).AutoColorization
        $curAcc = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\DWM' -Name AccentColor -ErrorAction SilentlyContinue).AccentColor
        if ($null -ne $curAuto -and $null -ne $curAcc) {
            Set-ItemProperty -Path $regDarkSwitch -Name "BackupAutoCol" -Value $curAuto -Type DWord -Force
            Set-ItemProperty -Path $regDarkSwitch -Name "BackupAccCol" -Value $curAcc -Type DWord -Force
            if ($curAuto -ne 1 -and $curAcc -ne $null) {
                $r = ($curAcc -band 0xFF).ToString("X2"); $g = (($curAcc -shr 8) -band 0xFF).ToString("X2"); $b = (($curAcc -shr 16) -band 0xFF).ToString("X2")
                $accStr = "#$r$g$b"
                Set-ItemProperty -Path $regDarkSwitch -Name "LightAccMode" -Value 2 -Type DWord -Force
                Set-ItemProperty -Path $regDarkSwitch -Name "DarkAccMode" -Value 2 -Type DWord -Force
                Set-ItemProperty -Path $regDarkSwitch -Name "LightAccCustom" -Value $accStr -Force
                Set-ItemProperty -Path $regDarkSwitch -Name "DarkAccCustom" -Value $accStr -Force
                Set-ItemProperty -Path $regDarkSwitch -Name "LightAccent" -Value $accStr -Force
                Set-ItemProperty -Path $regDarkSwitch -Name "DarkAccent" -Value $accStr -Force
            } else {
                Set-ItemProperty -Path $regDarkSwitch -Name "LightAccMode" -Value 0 -Type DWord -Force
                Set-ItemProperty -Path $regDarkSwitch -Name "DarkAccMode" -Value 0 -Type DWord -Force
                Set-ItemProperty -Path $regDarkSwitch -Name "LightAccent" -Value "auto" -Force
                Set-ItemProperty -Path $regDarkSwitch -Name "DarkAccent" -Value "auto" -Force
            }
        }
    } else {
        if (-not $config.ContainsKey("LightAccMode")) { Set-ItemProperty -Path $regDarkSwitch -Name "LightAccMode" -Value 0 -Type DWord -Force }
        if (-not $config.ContainsKey("DarkAccMode")) { Set-ItemProperty -Path $regDarkSwitch -Name "DarkAccMode" -Value 0 -Type DWord -Force }
        if (-not $config.ContainsKey("LightAccWinColor")) { Set-ItemProperty -Path $regDarkSwitch -Name "LightAccWinColor" -Value "#0078D4" -Force }
        if (-not $config.ContainsKey("DarkAccWinColor")) { Set-ItemProperty -Path $regDarkSwitch -Name "DarkAccWinColor" -Value "#0078D4" -Force }
        if (-not $config.ContainsKey("LightAccCustom")) { Set-ItemProperty -Path $regDarkSwitch -Name "LightAccCustom" -Value "#0078D4" -Force }
        if (-not $config.ContainsKey("DarkAccCustom")) { Set-ItemProperty -Path $regDarkSwitch -Name "DarkAccCustom" -Value "#0078D4" -Force }
    }

    Write-Host "$e[36m[2/9] Compiling Native C# Engine for maximum performance...$e[0m"
    $csharpEngineCode = @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using Microsoft.Win32;

namespace DarkSwitch {
    public class SunCalc {
        public static DateTime[] GetSunTimes(double lat, double lon, DateTime date) {
            try {
                int N = date.DayOfYear;
                double lngHour = lon / 15.0;
                double t_rise = N + ((6.0 - lngHour) / 24.0);
                double t_set = N + ((18.0 - lngHour) / 24.0);

                double M_rise = (0.9856 * t_rise) - 3.289;
                double M_set = (0.9856 * t_set) - 3.289;

                double L_rise = (M_rise + (1.916 * Math.Sin(M_rise * Math.PI/180.0)) + (0.020 * Math.Sin(2 * M_rise * Math.PI/180.0)) + 282.634) % 360.0;
                double L_set = (M_set + (1.916 * Math.Sin(M_set * Math.PI/180.0)) + (0.020 * Math.Sin(2 * M_set * Math.PI/180.0)) + 282.634) % 360.0;
                if(L_rise < 0) L_rise += 360.0; if(L_set < 0) L_set += 360.0;

                double RA_rise = (180.0/Math.PI) * Math.Atan(0.91764 * Math.Tan(L_rise * Math.PI/180.0));
                double RA_set = (180.0/Math.PI) * Math.Atan(0.91764 * Math.Tan(L_set * Math.PI/180.0));
                RA_rise = (RA_rise % 360.0); if(RA_rise < 0) RA_rise += 360.0;
                RA_set = (RA_set % 360.0); if(RA_set < 0) RA_set += 360.0;

                double Lquadrant_rise  = (Math.Floor( L_rise/90.0)) * 90.0;
                double RAquadrant_rise = (Math.Floor(RA_rise/90.0)) * 90.0;
                RA_rise = RA_rise + (Lquadrant_rise - RAquadrant_rise);
                RA_rise = RA_rise / 15.0;

                double Lquadrant_set  = (Math.Floor( L_set/90.0)) * 90.0;
                double RAquadrant_set = (Math.Floor(RA_set/90.0)) * 90.0;
                RA_set = RA_set + (Lquadrant_set - RAquadrant_set);
                RA_set = RA_set / 15.0;

                double sinDec_rise = 0.39782 * Math.Sin(L_rise * Math.PI/180.0);
                double cosDec_rise = Math.Cos(Math.Asin(sinDec_rise));
                double sinDec_set = 0.39782 * Math.Sin(L_set * Math.PI/180.0);
                double cosDec_set = Math.Cos(Math.Asin(sinDec_set));

                double cosH_rise = (Math.Cos(90.833 * Math.PI/180.0) - (sinDec_rise * Math.Sin(lat * Math.PI/180.0))) / (cosDec_rise * Math.Cos(lat * Math.PI/180.0));
                double cosH_set = (Math.Cos(90.833 * Math.PI/180.0) - (sinDec_set * Math.Sin(lat * Math.PI/180.0))) / (cosDec_set * Math.Cos(lat * Math.PI/180.0));

                if (cosH_rise > 1 || cosH_rise < -1) return new DateTime[] { DateTime.MinValue, DateTime.MinValue };

                double H_rise = (360.0 - (180.0/Math.PI) * Math.Acos(cosH_rise)) / 15.0;
                double H_set = ((180.0/Math.PI) * Math.Acos(cosH_set)) / 15.0;

                double T_rise = H_rise + RA_rise - (0.06571 * t_rise) - 6.622;
                double T_set = H_set + RA_set - (0.06571 * t_set) - 6.622;

                double UT_rise = (T_rise - lngHour) % 24.0; if(UT_rise < 0) UT_rise += 24.0;
                double UT_set = (T_set - lngHour) % 24.0; if(UT_set < 0) UT_set += 24.0;

                DateTime rise = new DateTime(date.Year, date.Month, date.Day, 0, 0, 0, DateTimeKind.Utc).AddHours(UT_rise).ToLocalTime();
                DateTime set = new DateTime(date.Year, date.Month, date.Day, 0, 0, 0, DateTimeKind.Utc).AddHours(UT_set).ToLocalTime();

                return new DateTime[] { rise, set };
            } catch { return new DateTime[] { DateTime.MinValue, DateTime.MinValue }; }
        }
    }

    public class Engine {
        [StructLayout(LayoutKind.Sequential)]
        public struct IMMERSIVE_COLOR_PREFERENCE {
            public uint dwColorSpace;
            public uint dwColor;
        }

        [DllImport("uxtheme.dll", EntryPoint = "#122")]
        public static extern int SetUserColorPreference(ref IMMERSIVE_COLOR_PREFERENCE pcpPreference, bool fForceCommit);

        [DllImport("uxtheme.dll", EntryPoint = "#104")] public static extern void RefreshImmersiveColorPolicyState();
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern bool SendNotifyMessage(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam);
        [DllImport("shell32.dll", CharSet = CharSet.Auto)] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);

        [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
        public static extern void SHCreateItemFromParsingName([In][MarshalAs(UnmanagedType.LPWStr)] string pszPath, [In] IntPtr pbc, [In] ref Guid riid, out IntPtr ppv);

        [DllImport("shell32.dll", PreserveSig = false)]
        public static extern void SHCreateShellItemArrayFromShellItem([In] IntPtr psi, [In] ref Guid riid, out IntPtr ppv);

        [ComImport, Guid("C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD")] public class DesktopWallpaper { }
        
        [ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] 
        public interface IDesktopWallpaper {
            void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] string wallpaper);
            void GetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] out string wallpaper);
            void GetMonitorDevicePathAt(uint monitorIndex, [MarshalAs(UnmanagedType.LPWStr)] out string monitorID);
            void GetMonitorDevicePathCount(out uint count);
            void GetMonitorRECT([MarshalAs(UnmanagedType.LPWStr)] string monitorID, out IntPtr displayRect);
            void SetBackgroundColor(uint color);
            void GetBackgroundColor(out uint color);
            void SetPosition(uint position);
            void GetPosition(out uint position);
            void SetSlideshow(IntPtr items);
            void GetSlideshow(out IntPtr items);
            void SetSlideshowOptions(uint options, uint slideshowTick);
        }

        public static void Main() { Toggle(); }

        public static void RefreshTheme() {
            try { RefreshImmersiveColorPolicyState(); } catch {}
            
            IntPtr HWND_BROADCAST = (IntPtr)0xFFFF;
            uint SMTO_ABORTIFHUNG = 0x0002;
            
            SendNotifyMessage(HWND_BROADCAST, 0x001A, IntPtr.Zero, "ImmersiveColorSet");
            SendNotifyMessage(HWND_BROADCAST, 0x001A, IntPtr.Zero, "AppsUseLightTheme");
            SendNotifyMessage(HWND_BROADCAST, 0x001A, IntPtr.Zero, "SystemUsesLightTheme");
            SendNotifyMessage(HWND_BROADCAST, 0x031A, IntPtr.Zero, null);

            IntPtr res;
            SendMessageTimeout(HWND_BROADCAST, 0x001A, IntPtr.Zero, "ImmersiveColorSet", SMTO_ABORTIFHUNG, 25, out res);
            SendMessageTimeout(HWND_BROADCAST, 0x031A, IntPtr.Zero, null, SMTO_ABORTIFHUNG, 25, out res);
            SendMessageTimeout(HWND_BROADCAST, 0x001A, IntPtr.Zero, "WindowsThemeElement", SMTO_ABORTIFHUNG, 25, out res);
            
            try { SHChangeNotify(0x08000000, 0x0000, IntPtr.Zero, IntPtr.Zero); } catch {}
        }

        public static void ApplyCursor(string schemeName) {
            if (string.IsNullOrEmpty(schemeName)) return;
            using (RegistryKey cursors = Registry.CurrentUser.CreateSubKey(@"Control Panel\Cursors")) {
                if (cursors == null) return;
                if (schemeName.ToLower() == "none" || schemeName.ToLower() == "windows default") {
                    cursors.SetValue("", "Windows Default");
                    string[] keys = { "Arrow", "Help", "AppStarting", "Wait", "Crosshair", "IBeam", "NWPen", "No", "SizeNS", "SizeWE", "SizeNWSE", "SizeNESW", "SizeAll", "UpArrow", "Hand" };
                    foreach(string k in keys) cursors.DeleteValue(k, false);
                } else {
                    object val = null;
                    using (RegistryKey userSchemes = Registry.CurrentUser.OpenSubKey(@"Control Panel\Cursors\Schemes")) {
                        if (userSchemes != null) val = userSchemes.GetValue(schemeName);
                    }
                    if (val == null) {
                        using (RegistryKey sysSchemes = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\Cursors\Schemes")) {
                            if (sysSchemes != null) val = sysSchemes.GetValue(schemeName);
                        }
                    }

                    if (val != null) {
                        string[] paths = val.ToString().Split(',');
                        string[] keys = { "Arrow", "Help", "AppStarting", "Wait", "Crosshair", "IBeam", "NWPen", "No", "SizeNS", "SizeWE", "SizeNWSE", "SizeNESW", "SizeAll", "UpArrow", "Hand" };
                        cursors.SetValue("", schemeName);
                        for (int i = 0; i < Math.Min(keys.Length, paths.Length); i++) {
                            if (!string.IsNullOrEmpty(paths[i])) cursors.SetValue(keys[i], paths[i]);
                            else cursors.DeleteValue(keys[i], false);
                        }
                    }
                }
            }
            SystemParametersInfo(0x0057, 0, null, 0x01 | 0x02);
        }

        private static string HexToRgb(string hex) {
            if(string.IsNullOrEmpty(hex)) return "0 0 0";
            if(hex.StartsWith("#")) hex = hex.Substring(1);
            if(hex.Length != 6) return "0 0 0";
            try {
                int r = Convert.ToInt32(hex.Substring(0,2), 16);
                int g = Convert.ToInt32(hex.Substring(2,2), 16);
                int b = Convert.ToInt32(hex.Substring(4,2), 16);
                return r + " " + g + " " + b;
            } catch { return "0 0 0"; }
        }

        public static void ApplyWpMode(int mode, string file, string colorHex, string folder, int tick) {
            using (RegistryKey expWp = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers"))
            using (RegistryKey cpColors = Registry.CurrentUser.CreateSubKey(@"Control Panel\Colors")) {
                if (mode == 2 && string.IsNullOrEmpty(folder)) { mode = 0; }
                if (expWp != null) expWp.SetValue("BackgroundType", mode, RegistryValueKind.DWord);
                
                IDesktopWallpaper dw = null;
                try { dw = (IDesktopWallpaper)new DesktopWallpaper(); } catch {}

                if (mode == 0 && !string.IsNullOrEmpty(file)) {
                    try { if(dw != null) dw.SetWallpaper(null, file); } 
                    catch { SystemParametersInfo(20, 0, file, 3); }
                }
                else if (mode == 1 && !string.IsNullOrEmpty(colorHex)) {
                    string rgb = HexToRgb(colorHex);
                    if (cpColors != null) cpColors.SetValue("Background", rgb, RegistryValueKind.String);
                    
                    try {
                        string h = colorHex.StartsWith("#") ? colorHex.Substring(1) : colorHex;
                        if(h.Length == 6) {
                            int r = Convert.ToInt32(h.Substring(0,2), 16);
                            int g = Convert.ToInt32(h.Substring(2,2), 16);
                            int b = Convert.ToInt32(h.Substring(4,2), 16);
                            uint color = (uint)(r | (g << 8) | (b << 16));
                            
                            if(dw != null) { dw.SetWallpaper(null, ""); dw.SetBackgroundColor(color); }
                        }
                    } catch {}
                    
                    SystemParametersInfo(20, 0, "", 3);
                }
                else if (mode == 2 && !string.IsNullOrEmpty(folder)) {
                    if (expWp != null) {
                        expWp.SetValue("SlideshowDirectoryPath1", folder, RegistryValueKind.String);
                        expWp.SetValue("SlideshowTick", tick, RegistryValueKind.DWord);
                    }
                    
                    try {
                        if (dw != null) {
                            Guid iidShellItem = new Guid("43826d1e-e718-42ee-bc55-a1e261c37bfe");
                            IntPtr pItem = IntPtr.Zero;
                            SHCreateItemFromParsingName(folder, IntPtr.Zero, ref iidShellItem, out pItem);
                            
                            if (pItem != IntPtr.Zero) {
                                Guid iidShellItemArray = new Guid("b63ea76d-1f85-456f-a19c-48159efa858b");
                                IntPtr pArray = IntPtr.Zero;
                                SHCreateShellItemArrayFromShellItem(pItem, ref iidShellItemArray, out pArray);

                                if (pArray != IntPtr.Zero) {
                                    dw.SetSlideshow(pArray);
                                    dw.SetSlideshowOptions(0, (uint)tick);
                                    Marshal.Release(pArray);
                                }
                                Marshal.Release(pItem);
                            }
                        }
                    } catch { SystemParametersInfo(20, 0, "", 3); }
                }
            }
        }

        public static void ApplyAcc(string acc) {
            if (string.IsNullOrEmpty(acc)) return;
            ApplyAccInternal(acc);
            RefreshTheme();
        }

        private static void ApplyAccInternal(string acc) {
            if (acc.ToLower() == "auto") {
                using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { 
                    if (desk != null) { desk.SetValue("AutoColorization", 1, RegistryValueKind.DWord); desk.Flush(); }
                }
            } else {
                using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { 
                    if (desk != null) { desk.SetValue("AutoColorization", 0, RegistryValueKind.DWord); desk.Flush(); }
                }
                try {
                    int abgr = 0;
                    int argb = 0;
                    string h = acc.StartsWith("#") ? acc.Substring(1) : acc;
                    int r = 0, g = 0, b = 0;
                    if(h.Length == 6) {
                        r = Convert.ToInt32(h.Substring(0,2), 16); 
                        g = Convert.ToInt32(h.Substring(2,2), 16); 
                        b = Convert.ToInt32(h.Substring(4,2), 16);
                        abgr = (b << 16) | (g << 8) | r;
                        argb = unchecked((int)0xFF000000) | (r << 16) | (g << 8) | b;
                    }

                    try {
                        IMMERSIVE_COLOR_PREFERENCE pref = new IMMERSIVE_COLOR_PREFERENCE();
                        pref.dwColorSpace = 0;
                        pref.dwColor = unchecked((uint)abgr);
                        SetUserColorPreference(ref pref, true);
                    } catch {} 

                    using (RegistryKey dwm = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\DWM")) {
                        if (dwm != null) {
                            dwm.SetValue("AccentColor", abgr, RegistryValueKind.DWord);
                            dwm.SetValue("ColorizationColor", argb, RegistryValueKind.DWord);
                            dwm.Flush();
                        }
                    }
                    using (RegistryKey accent = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Explorer\Accent")) {
                        if (accent != null) {
                            accent.SetValue("AccentColorMenu", abgr, RegistryValueKind.DWord);
                            accent.SetValue("StartColorMenu", abgr, RegistryValueKind.DWord);
                            
                            byte[] palette = new byte[32];
                            for (int i = 0; i < 8; i++) {
                                palette[i * 4] = (byte)r;
                                palette[i * 4 + 1] = (byte)g;
                                palette[i * 4 + 2] = (byte)b;
                                palette[i * 4 + 3] = 0;
                            }
                            accent.SetValue("AccentPalette", palette, RegistryValueKind.Binary);
                            accent.Flush();
                        }
                    }
                } catch {}
            }
        }

        public static void RestoreAccent(int autoCol, long accColLong) {
            int accCol = unchecked((int)accColLong);
            try {
                if (autoCol == 0) {
                    IMMERSIVE_COLOR_PREFERENCE pref = new IMMERSIVE_COLOR_PREFERENCE();
                    pref.dwColorSpace = 0;
                    pref.dwColor = unchecked((uint)accCol);
                    SetUserColorPreference(ref pref, true);
                }
            } catch {}

            using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { 
                if (desk != null) { desk.SetValue("AutoColorization", autoCol, RegistryValueKind.DWord); desk.Flush(); }
            }
            using (RegistryKey dwm = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\DWM")) { 
                if (dwm != null) {
                    dwm.SetValue("AccentColor", accCol, RegistryValueKind.DWord); 
                    dwm.SetValue("ColorizationColor", accCol | unchecked((int)0xFF000000), RegistryValueKind.DWord);
                    dwm.Flush();
                }
            }
            using (RegistryKey accent = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Explorer\Accent")) {
                if (accent != null) {
                    accent.SetValue("AccentColorMenu", accCol, RegistryValueKind.DWord);
                    accent.SetValue("StartColorMenu", accCol, RegistryValueKind.DWord);

                    int r = accCol & 0xFF; int g = (accCol >> 8) & 0xFF; int b = (accCol >> 16) & 0xFF;
                    byte[] palette = new byte[32];
                    for (int i = 0; i < 8; i++) {
                        palette[i * 4] = (byte)r; palette[i * 4 + 1] = (byte)g; palette[i * 4 + 2] = (byte)b; palette[i * 4 + 3] = 0;
                    }
                    accent.SetValue("AccentPalette", palette, RegistryValueKind.Binary);
                    accent.Flush();
                }
            }
            RefreshTheme();
        }

        public static void Execute(int isLight, bool doWp, int wpMode, string wpFile, string wpColor, string wpFolder, int wpTick, string acc, string cur) {
            try {
                Process.GetCurrentProcess().PriorityClass = ProcessPriorityClass.RealTime;
                System.Threading.Thread.CurrentThread.Priority = System.Threading.ThreadPriority.Highest;
            } catch {}

            if (!string.IsNullOrEmpty(cur)) ApplyCursor(cur);

            if (isLight != -1) {
                using (RegistryKey reg = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", true)) {
                    if (reg != null) {
                        reg.SetValue("AppsUseLightTheme", isLight, RegistryValueKind.DWord);
                        reg.SetValue("SystemUsesLightTheme", isLight, RegistryValueKind.DWord);
                        reg.Flush();
                    }
                }
            }

            if (!string.IsNullOrEmpty(acc)) ApplyAccInternal(acc);

            if (doWp) ApplyWpMode(wpMode, wpFile, wpColor, wpFolder, wpTick);

            if (isLight != -1 || !string.IsNullOrEmpty(acc) || doWp || !string.IsNullOrEmpty(cur)) {
                RefreshTheme();
            }
        }

        public static void RefreshCurrent() {
            try {
                using (RegistryKey regDM = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\DarkSwitch")) {
                    if (regDM != null) {
                        int currentVal = 1;
                        using (RegistryKey regTheme = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize")) {
                            if (regTheme != null) {
                                object val = regTheme.GetValue("AppsUseLightTheme");
                                if (val != null && Convert.ToInt32(val) == 0) currentVal = 0;
                            }
                        }
                        
                        int wpMode = 0; string wpFile = ""; string wpColor = ""; string wpFolder = ""; int wpTick = 600000;
                        object wpEn = regDM.GetValue("WallpaperEnabled");
                        bool doWp = wpEn != null && Convert.ToInt32(wpEn) == 1;
                        if (doWp) {
                            wpMode = Convert.ToInt32(regDM.GetValue(currentVal == 1 ? "LightWpMode" : "DarkWpMode", 0));
                            wpFile = (string)regDM.GetValue(currentVal == 1 ? "LightWpFile" : "DarkWpFile", "");
                            wpColor = (string)regDM.GetValue(currentVal == 1 ? "LightWpColor" : "DarkWpColor", "");
                            wpFolder = (string)regDM.GetValue(currentVal == 1 ? "LightWpFolder" : "DarkWpFolder", "");
                            wpTick = Convert.ToInt32(regDM.GetValue(currentVal == 1 ? "LightWpInterval" : "DarkWpInterval", 600000));
                        }
                        
                        string acc = "";
                        object accEn = regDM.GetValue("AccentEnabled");
                        if (accEn != null && Convert.ToInt32(accEn) == 1) {
                            acc = (string)regDM.GetValue(currentVal == 1 ? "LightAccent" : "DarkAccent");
                        }
                        
                        string cur = "";
                        object curEn = regDM.GetValue("CursorEnabled");
                        if (curEn != null && Convert.ToInt32(curEn) == 1) {
                            cur = (string)regDM.GetValue(currentVal == 1 ? "LightCursor" : "DarkCursor");
                        }
                        
                        Execute(currentVal, doWp, wpMode, wpFile, wpColor, wpFolder, wpTick, acc, cur);
                    }
                }
            } catch {}
        }

        public static void Toggle() {
            try {
                long ticks = DateTime.Now.Ticks;
                using (RegistryKey regDM = Registry.CurrentUser.CreateSubKey(@"SOFTWARE\DarkSwitch")) {
                    if (regDM != null) {
                        regDM.SetValue("OverrideTime", ticks, RegistryValueKind.QWord);
                        int newVal = 1;
                        using (RegistryKey regTheme = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize")) {
                            if (regTheme != null) {
                                object val = regTheme.GetValue("AppsUseLightTheme");
                                if (val != null && Convert.ToInt32(val) == 1) newVal = 0;
                            }
                        }
                        
                        int wpMode = 0; string wpFile = ""; string wpColor = ""; string wpFolder = ""; int wpTick = 600000;
                        object wpEn = regDM.GetValue("WallpaperEnabled");
                        bool doWp = wpEn != null && Convert.ToInt32(wpEn) == 1;
                        if (doWp) {
                            wpMode = Convert.ToInt32(regDM.GetValue(newVal == 1 ? "LightWpMode" : "DarkWpMode", 0));
                            wpFile = (string)regDM.GetValue(newVal == 1 ? "LightWpFile" : "DarkWpFile", "");
                            wpColor = (string)regDM.GetValue(newVal == 1 ? "LightWpColor" : "DarkWpColor", "");
                            wpFolder = (string)regDM.GetValue(newVal == 1 ? "LightWpFolder" : "DarkWpFolder", "");
                            wpTick = Convert.ToInt32(regDM.GetValue(newVal == 1 ? "LightWpInterval" : "DarkWpInterval", 600000));
                        }
                        
                        string acc = "";
                        object accEn = regDM.GetValue("AccentEnabled");
                        if (accEn != null && Convert.ToInt32(accEn) == 1) {
                            acc = (string)regDM.GetValue(newVal == 1 ? "LightAccent" : "DarkAccent");
                        }
                        
                        string cur = "";
                        object curEn = regDM.GetValue("CursorEnabled");
                        if (curEn != null && Convert.ToInt32(curEn) == 1) {
                            cur = (string)regDM.GetValue(newVal == 1 ? "LightCursor" : "DarkCursor");
                        }
                        
                        Execute(newVal, doWp, wpMode, wpFile, wpColor, wpFolder, wpTick, acc, cur);
                    }
                }
            } catch {}
        }
    }
}
'@

    try {
        Add-Type -TypeDefinition $csharpEngineCode -OutputAssembly $dllPath -OutputType Library -ErrorAction Stop
    } catch {
        Write-Host "  [!] Warning: C# Engine Compilation failed. Please ensure .NET is intact.$e[0m" -ForegroundColor Red
        exit 1
    }

    Write-Host "$e[36m[3/9] Generating Unified Core Engine...$e[0m"
    $coreEngineContent = @"
param([string]`$Action = 'SYNC')
`$regDM = `"HKCU:\SOFTWARE\DarkSwitch`"
`$regData = Get-ItemProperty `$regDM -ErrorAction SilentlyContinue
if (-not `$regData) { exit }

`$dllPath = `"C:\Program Files\Detaroxz\DarkSwitch\Engine\DarkSwitchEngine.dll`"
if (Test-Path `$dllPath) { [Reflection.Assembly]::LoadFile(`$dllPath) | Out-Null }

`$now = [datetime]::Now
`$dynSun = (`$regData.DynamicSun -eq 'Y')

if (`$Action -eq 'SUN' -or (`$Action -eq 'BOOT' -and `$dynSun)) {
    if (`$dynSun -and `$regData.LastLat -and `$regData.LastLon) {
        `$latStr = `$regData.LastLat.ToString()
        `$lonStr = `$regData.LastLon.ToString()
        `$lat = [double]::Parse(`$latStr.Replace(',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
        `$lon = [double]::Parse(`$lonStr.Replace(',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
        `$times = [DarkSwitch.SunCalc]::GetSunTimes(`$lat, `$lon, `$now)
        
        if (`$times[0] -ne [datetime]::MinValue) {
            `$tPath = `"\Detaroxz\DarkSwitch\`"
            try {
                `$tL = Get-ScheduledTask -TaskName `"DarkSwitch - Light Mode`" -TaskPath `$tPath -ErrorAction Stop
                `$tL.Triggers[0].StartBoundary = `$times[0].ToString(`"yyyy-MM-ddTHH:mm:ss`")
                `$tL | Set-ScheduledTask -User `$env:USERNAME -ErrorAction Stop | Out-Null
            } catch {}
            try {
                `$tD = Get-ScheduledTask -TaskName `"DarkSwitch - Dark Mode`" -TaskPath `$tPath -ErrorAction Stop
                `$tD.Triggers[0].StartBoundary = `$times[1].ToString(`"yyyy-MM-ddTHH:mm:ss`")
                `$tD | Set-ScheduledTask -User `$env:USERNAME -ErrorAction Stop | Out-Null
            } catch {}
        }
    }
}

`$isLight = `$false

if (`$Action -eq 'SYNC_LIGHT') {
    `$isLight = `$true
    Set-ItemProperty `$regDM -Name `"OverrideTime`" -Value 0 -Type QWord -Force -ErrorAction SilentlyContinue
} elseif (`$Action -eq 'SYNC_DARK') {
    `$isLight = `$false
    Set-ItemProperty `$regDM -Name `"OverrideTime`" -Value 0 -Type QWord -Force -ErrorAction SilentlyContinue
} else {
    `$tLight = Get-ScheduledTask -TaskPath `"\Detaroxz\DarkSwitch\`" -TaskName `"DarkSwitch - Light Mode`" -ErrorAction SilentlyContinue
    `$tDark = Get-ScheduledTask -TaskPath `"\Detaroxz\DarkSwitch\`" -TaskName `"DarkSwitch - Dark Mode`" -ErrorAction SilentlyContinue
    if (`$tLight -and `$tDark -and `$tLight.State -ne 'Disabled') {
        `$lTime = [datetime](`$tLight.Triggers[0].StartBoundary)
        `$dTime = [datetime](`$tDark.Triggers[0].StartBoundary)
        `$todayL = `$now.Date + `$lTime.TimeOfDay
        `$todayD = `$now.Date + `$dTime.TimeOfDay
        `$pastL = if (`$now -ge `$todayL) { `$todayL } else { `$todayL.AddDays(-1) }
        `$pastD = if (`$now -ge `$todayD) { `$todayD } else { `$todayD.AddDays(-1) }
        `$recentB = if (`$pastL -gt `$pastD) { `$pastL } else { `$pastD }
        
        if (`$Action -eq 'SYNC') { Set-ItemProperty `$regDM -Name `"OverrideTime`" -Value 0 -Type QWord -Force -ErrorAction SilentlyContinue }
        `$overrideTicks = (Get-ItemProperty `$regDM -Name `"OverrideTime`" -ErrorAction SilentlyContinue).OverrideTime
        if (`$overrideTicks -and [long]`$overrideTicks -gt `$recentB.Ticks) { exit }
        
        `$isLight = (`$recentB -eq `$pastL)
    } else { exit }
}

`$newVal = if (`$isLight) { 1 } else { 0 }
`$regTheme = `"HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize`"
`$currApp = (Get-ItemProperty -Path `$regTheme -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme

if (`$currApp -ne `$newVal -or `$Action -eq 'BOOT') {
    `$wpEnBool = (`$regData.WallpaperEnabled -eq 1)
    `$wpMode = 0; `$wpFile = `""; `$wpColor = `""; `$wpFolder = `""; `$wpTick = 600000
    if (`$wpEnBool) {
        `$wpMode = if (`$newVal -eq 1) { `$regData.LightWpMode } else { `$regData.DarkWpMode }
        `$wpFile = if (`$newVal -eq 1) { `$regData.LightWpFile } else { `$regData.DarkWpFile }
        `$wpColor = if (`$newVal -eq 1) { `$regData.LightWpColor } else { `$regData.DarkWpColor }
        `$wpFolder = if (`$newVal -eq 1) { `$regData.LightWpFolder } else { `$regData.DarkWpFolder }
        `$wpTick = if (`$newVal -eq 1) { `$regData.LightWpInterval } else { `$regData.DarkWpInterval }
    }
    `$acc = `"`"
    if (`$regData.AccentEnabled -eq 1) { `$acc = if (`$newVal -eq 1) { `$regData.LightAccent } else { `$regData.DarkAccent } }
    
    `$cur = `"`"
    if (`$regData.CursorEnabled -eq 1) { `$cur = if (`$newVal -eq 1) { `$regData.LightCursor } else { `$regData.DarkCursor } }
    
    [DarkSwitch.Engine]::Execute(`$newVal, `$wpEnBool, [int]`$wpMode, `"`$wpFile`", `"`$wpColor`", `"`$wpFolder`", [int]`$wpTick, `"`$acc`", `"`$cur`")
}
exit
"@
    Set-Content -Path $coreEnginePath -Value $coreEngineContent -Force

    Write-Host "$e[36m[4/9] Generating Stealth Runners...$e[0m"
    $vbsContent = @'
Set WshShell = CreateObject("WScript.Shell")
scriptPath = WScript.Arguments(0)
args = ""
For i = 1 to WScript.Arguments.Count - 1
    args = args & " """ & WScript.Arguments(i) & """"
Next
WshShell.Run "powershell.exe -Sta -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & scriptPath & """" & args, 0, False
'@
    Set-Content -Path $vbsRunnerPath -Value $vbsContent -Force

    $toggleVbsContent = @'
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -Command ""[Reflection.Assembly]::LoadFile('C:\Program Files\Detaroxz\DarkSwitch\Engine\DarkSwitchEngine.dll') | Out-Null; [DarkSwitch.Engine]::Toggle()""", 0, False
'@
    Set-Content -Path "$engineDir\Toggle.vbs" -Value $toggleVbsContent -Force

    Write-Host "$e[36m[5/9] Generating Interactive Core...$e[0m"
    $settingsScriptContent = @"
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    `$hasWT = (Test-Path "`$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe") -or [bool](Get-Item "`$env:windir\System32\wt.exe" -ErrorAction SilentlyContinue)
    if (`$hasWT) {
        Start-Process wt.exe -Verb RunAs -ArgumentList "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \`"`$PSCommandPath\`""
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"`$PSCommandPath`""
    }
    exit
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
`$e = [char]27
`$smPath = [Environment]::GetFolderPath("CommonApplicationData") + "\Microsoft\Windows\Start Menu\Programs\DarkSwitch"
`$wpDir = "C:\Program Files\Detaroxz\DarkSwitch\Wallpapers"
`$engineDir = "C:\Program Files\Detaroxz\DarkSwitch\Engine"
`$vbs = "`$engineDir\RunSilent.vbs"
`$p = New-ScheduledTaskPrincipal -UserId `$env:USERNAME -LogonType Interactive -RunLevel Highest
`$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 1) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
`$tPath = "\Detaroxz\DarkSwitch\"
`$appVersion = "$appVersion"

`$is24Hour = (Get-Culture).DateTimeFormat.ShortTimePattern -cmatch 'H'
`$timeFormat = if (`$is24Hour) { "HH:mm" } else { "h:mm tt" }
`$timeHint = if (`$is24Hour) { "HH:MM (e.g., 07:00, 19:30)" } else { "HH:MM AM/PM" }
`$defLight = if (`$is24Hour) { "07:00" } else { "7:00 AM" }
`$defDark = if (`$is24Hour) { "19:00" } else { "7:00 PM" }
`$defSun1 = if (`$is24Hour) { "00:00" } else { "12:00 AM" }

`$WshShell = New-Object -ComObject WScript.Shell
`$scTogglePath = "`$smPath\Quick Toggle.lnk"

# Color Palette Setup
`$cMain = "`$e[38;5;51m"; `$cAccent = "`$e[38;5;213m"; `$cText = "`$e[97m"; `$cDim = "`$e[90m"; `$cGreen = "`$e[38;5;46m"; `$cRed = "`$e[38;5;196m"; `$cYellow = "`$e[38;5;226m"; `$cReset = "`$e[0m"; `$cHeading = "`$e[38;5;205m"

`$global:winColors = @(
    @{ Name="Gold"; Hex="#FFB900" }, @{ Name="Orange"; Hex="#FF8C00" }, @{ Name="Dark Orange"; Hex="#F7630C" },
    @{ Name="Brown Orange"; Hex="#CA5010" }, @{ Name="Burnt Orange"; Hex="#DA3B01" }, @{ Name="Coral"; Hex="#EF6950" },
    @{ Name="Rose"; Hex="#DC6769" }, @{ Name="Bright Red"; Hex="#FF4343" }, @{ Name="Red"; Hex="#E74856" },
    @{ Name="Crimson"; Hex="#E81123" }, @{ Name="Hot Pink"; Hex="#EA005E" }, @{ Name="Dark Pink"; Hex="#C30052" },
    @{ Name="Magenta"; Hex="#E3008C" }, @{ Name="Dark Magenta"; Hex="#BF0077" }, @{ Name="Orchid"; Hex="#C239B3" },
    @{ Name="Purple"; Hex="#9A0089" }, @{ Name="Blue"; Hex="#0078D4" }, @{ Name="Dark Blue"; Hex="#0063B1" },
    @{ Name="Lavender"; Hex="#8E8CD8" }, @{ Name="Indigo"; Hex="#6B69D6" }, @{ Name="Violet"; Hex="#8764B8" },
    @{ Name="Deep Purple"; Hex="#744DA9" }, @{ Name="Light Purple"; Hex="#B146C2" }, @{ Name="Plum"; Hex="#881798" },
    @{ Name="Cyan"; Hex="#0099BC" }, @{ Name="Steel Blue"; Hex="#2D7D9A" }, @{ Name="Turquoise"; Hex="#00B7C3" },
    @{ Name="Teal"; Hex="#038387" }, @{ Name="Mint"; Hex="#00B294" }, @{ Name="Dark Teal"; Hex="#018574" },
    @{ Name="Green"; Hex="#00CC6A" }, @{ Name="Dark Green"; Hex="#10893E" }, @{ Name="Warm Gray"; Hex="#7A7574" },
    @{ Name="Gray"; Hex="#5D5A58" }, @{ Name="Slate"; Hex="#68768A" }, @{ Name="Dark Slate"; Hex="#515C6B" },
    @{ Name="Sage"; Hex="#567C73" }, @{ Name="Dark Sage"; Hex="#486860" }, @{ Name="Olive"; Hex="#498205" },
    @{ Name="Forest Green"; Hex="#107C10" }, @{ Name="Medium Gray"; Hex="#767676" }, @{ Name="Charcoal"; Hex="#4C4A48" },
    @{ Name="Blue Gray"; Hex="#69797E" }, @{ Name="Dark Blue Gray"; Hex="#4A5459" }, @{ Name="Moss"; Hex="#647C64" },
    @{ Name="Olive Brown"; Hex="#8E7D47" }, @{ Name="Taupe"; Hex="#7E735F" }
)

`$global:wpSolidColors = @(
    @{ Name="Orange"; Hex="#FF8C00" }, @{ Name="Red"; Hex="#E81123" }, @{ Name="Dark Red"; Hex="#D13438" },
    @{ Name="Dark Pink"; Hex="#C30052" }, @{ Name="Dark Magenta"; Hex="#BF0077" }, @{ Name="Purple"; Hex="#9A0089" },
    @{ Name="Violet"; Hex="#8764B8" }, @{ Name="Dark Green"; Hex="#10893E" }, @{ Name="Forest Green"; Hex="#107C10" },
    @{ Name="Dark Teal"; Hex="#018574" }, @{ Name="Teal"; Hex="#038387" }, @{ Name="Blue"; Hex="#0078D4" },
    @{ Name="Indigo"; Hex="#6B69D6" }, @{ Name="Lavender"; Hex="#8E8CD8" }, @{ Name="Deep Purple"; Hex="#744DA9" },
    @{ Name="Plum"; Hex="#881798" }, @{ Name="Steel Blue"; Hex="#2D7D9A" }, @{ Name="Charcoal"; Hex="#4C4A48" },
    @{ Name="Taupe"; Hex="#7E735F" }, @{ Name="Olive Brown"; Hex="#8E7D47" }, @{ Name="Dark Slate"; Hex="#515C6B" },
    @{ Name="Dark Blue Gray"; Hex="#4A5459" }, @{ Name="Dark Gray"; Hex="#5D5A58" }, @{ Name="Black"; Hex="#000000" }
)

`$dllPath = "C:\Program Files\Detaroxz\DarkSwitch\Engine\DarkSwitchEngine.dll"
if (Test-Path `$dllPath) { [Reflection.Assembly]::LoadFile(`$dllPath) | Out-Null }

# Universal Sync Engines
function Set-ConfigValue {
    param(`$key, `$value, `$regType = "String")
    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\DarkSwitch" -Name `$key -Value `$value -Type `$regType -Force -ErrorAction Stop
        
        `$cfgPath = "C:\Program Files\Detaroxz\DarkSwitch\config.ini"
        `$cfg = @{}
        if (Test-Path `$cfgPath) {
            Get-Content `$cfgPath -ErrorAction SilentlyContinue | ForEach-Object {
                if (`$_ -match "^(.*?)=(.*)$") { `$cfg[`$matches[1].Trim()] = `$matches[2].Trim() }
            }
        }
        `$cfg[`$key] = `$value
        `$out = @()
        foreach (`$k in `$cfg.Keys) { `$out += "`$k=" + `$cfg[`$k] }
        `$out | Set-Content `$cfgPath -Force -ErrorAction Stop
    } catch {}
}

function Remove-ConfigValue {
    param(`$key)
    try {
        Remove-ItemProperty -Path "HKCU:\SOFTWARE\DarkSwitch" -Name `$key -ErrorAction SilentlyContinue
        `$cfgPath = "C:\Program Files\Detaroxz\DarkSwitch\config.ini"
        if (Test-Path `$cfgPath) {
            `$cfg = @{}
            Get-Content `$cfgPath -ErrorAction SilentlyContinue | ForEach-Object {
                if (`$_ -match "^(.*?)=(.*)$") { `$cfg[`$matches[1].Trim()] = `$matches[2].Trim() }
            }
            `$cfg.Remove(`$key)
            `$out = @()
            foreach (`$k in `$cfg.Keys) { `$out += "`$k=" + `$cfg[`$k] }
            `$out | Set-Content `$cfgPath -Force -ErrorAction Stop
        }
    } catch {}
}

if (-not ("Shell.WinAPI" -as [type])) {
    `$sig = '[DllImport("shell32.dll", CharSet=CharSet.Auto)] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);'
    Add-Type -MemberDefinition `$sig -Name WinAPI -Namespace Shell -PassThru | Out-Null
}

`$global:logFile = Join-Path `$env:TEMP "darkswitch_core_log.txt"
if (-not (Test-Path `$global:logFile)) { New-Item `$global:logFile -ItemType File -Force | Out-Null }
`$global:sectionLogs = @(Get-Content `$global:logFile -ErrorAction SilentlyContinue)
if (`$global:sectionLogs.Count -gt 5) { `$global:sectionLogs = `$global:sectionLogs[-5..-1] }

`$global:menuState = "Main"
`$global:selIndex = 0
`$global:currentOptions = @()
`$global:breadcrumb = "Core"
`$global:isLoading = `$false

`$syncHash = [hashtable]::Synchronized(@{ Run = `$false; Msg = ""; Top = 0 })
`$rs = [runspacefactory]::CreateRunspace()
`$rs.Open()
`$rs.SessionStateProxy.SetVariable("syncHash", `$syncHash)
`$psCmd = [powershell]::Create().AddScript({
    `$cYellow = [char]27 + "[38;5;226m"
    `$cReset = [char]27 + "[0m"
    `$chars = @('-', '\', '|', '/')
    `$i = 0
    while (`$true) {
        if (`$syncHash.Run) {
            try {
                [Console]::SetCursorPosition(0, `$syncHash.Top)
                [Console]::Write("  `$cYellow`$(`$chars[`$i % 4]) `$(`$syncHash.Msg)...`$cReset                    ")
            } catch {}
            `$i++
            [System.Threading.Thread]::Sleep(80)
        } else {
            [System.Threading.Thread]::Sleep(50)
        }
    }
})
`$psCmd.Runspace = `$rs
`$rsHandle = `$psCmd.BeginInvoke()

function Get-ColorBlock(`$hex) {
    if (`$hex -match '^#?([a-fA-F0-9]{6})$') {
        `$hex = `$matches[1]
        `$r = [Convert]::ToInt32(`$hex.Substring(0, 2), 16)
        `$g = [Convert]::ToInt32(`$hex.Substring(2, 2), 16)
        `$b = [Convert]::ToInt32(`$hex.Substring(4, 2), 16)
        return "`$e[38;2;`$r;`$g;`${b}m`$([char]0x25A0)`$cReset"
    }
    return "`$e[90m`$([char]0x25A0)`$cReset"
}

function Get-WinColorName(`$hex) {
    `$hex = "`#" + (`$hex -replace '#','').ToUpper()
    foreach (`$c in `$global:winColors) {
        if (`$c.Hex -eq `$hex) { return `$c.Name }
    }
    return `$hex
}

function Get-WpColorName(`$hex) {
    `$hex = "`#" + (`$hex -replace '#','').ToUpper()
    foreach (`$c in `$global:wpSolidColors) {
        if (`$c.Hex -eq `$hex) { return `$c.Name }
    }
    return `$hex
}

function Get-IntervalString(`$tick) {
    if (`$tick -eq 60000) { return "1 Minute" }
    if (`$tick -eq 600000) { return "10 Minutes" }
    if (`$tick -eq 1800000) { return "30 Minutes" }
    if (`$tick -eq 3600000) { return "1 Hour" }
    if (`$tick -eq 21600000) { return "6 Hours" }
    if (`$tick -eq 86400000) { return "1 Day" }
    return "`$tick ms"
}

function Get-Breadcrumb {
    switch (`$global:menuState) {
        "Main" { return "Core" }
        "Menu_General" { return "Core > General Settings" }
        "Menu_Mode" { return "Core > General Settings > Mode switch" }
        "Select_Mode_SubMenu" { return "Core > General Settings > Mode switch > Method of switch" }
        "Menu_Wallpaper" { return "Core > General Settings > Wallpaper switch" }
        "Menu_Wallpaper_Light" { return "Core > General Settings > Wallpaper switch > Light Mode Wallpaper" }
        "Menu_WpMode_L" { return "Core > General Settings > Wallpaper switch > Light Mode Wallpaper > Mode" }
        "Menu_WpColorType_L" { return "Core > General Settings > Wallpaper switch > Light Mode Wallpaper > Solid Color" }
        "Menu_Pick_WpWinColor_L" { return "Core > General Settings > Wallpaper switch > Light Mode Wallpaper > Solid Color > Windows color" }
        "Menu_WpInterval_L" { return "Core > General Settings > Wallpaper switch > Light Mode Wallpaper > Interval" }
        "Menu_Wallpaper_Dark" { return "Core > General Settings > Wallpaper switch > Dark Mode Wallpaper" }
        "Menu_WpMode_D" { return "Core > General Settings > Wallpaper switch > Dark Mode Wallpaper > Mode" }
        "Menu_WpColorType_D" { return "Core > General Settings > Wallpaper switch > Dark Mode Wallpaper > Solid Color" }
        "Menu_Pick_WpWinColor_D" { return "Core > General Settings > Wallpaper switch > Dark Mode Wallpaper > Solid Color > Windows color" }
        "Menu_WpInterval_D" { return "Core > General Settings > Wallpaper switch > Dark Mode Wallpaper > Interval" }
        "Menu_Accent" { return "Core > General Settings > Accent color switch" }
        "Menu_Accent_Light" { return "Core > General Settings > Accent color switch > Light Mode Accent Color" }
        "Menu_AccMode_L" { return "Core > General Settings > Accent color switch > Light Mode Accent Color > Mode" }
        "Menu_Pick_WinColor_L" { return "Core > General Settings > Accent color switch > Light Mode Accent Color > Windows color" }
        "Menu_Accent_Dark" { return "Core > General Settings > Accent color switch > Dark Mode Accent Color" }
        "Menu_AccMode_D" { return "Core > General Settings > Accent color switch > Dark Mode Accent Color > Mode" }
        "Menu_Pick_WinColor_D" { return "Core > General Settings > Accent color switch > Dark Mode Accent Color > Windows color" }
        "Menu_Cursor" { return "Core > General Settings > Cursor scheme switch" }
        "Menu_Pick_Cursor_L" { return "Core > General Settings > Cursor scheme switch > Light Mode Cursor" }
        "Menu_Pick_Cursor_D" { return "Core > General Settings > Cursor scheme switch > Dark Mode Cursor" }
        "Menu_Advanced" { return "Core > Advanced Settings" }
        "Menu_AdjustPriority" { return "Core > Advanced Settings > Adjust priority" }
        "Menu_Select_Prio_Sch" { return "Core > Advanced Settings > Adjust priority > Schedule Priority" }
        "Menu_Select_Prio_Boot" { return "Core > Advanced Settings > Adjust priority > Boot Sync Priority" }
        "Menu_Select_Prio_Sun" { return "Core > Advanced Settings > Adjust priority > Dynamic Calculator Priority" }
        "Menu_SystemIntegration" { return "Core > Advanced Settings > System integration" }
        "Menu_CoreSettings" { return "Core > Advanced Settings > Core settings" }
        "Menu_Tools" { return "Core > Tools" }
        "Menu_Update" { return "Core > Updates" }
        "Menu_About" { return "Core > About" }
        default { return "Core" }
    }
}

function Get-BackState {
    param(`$State)
    switch (`$State) {
        "Menu_Mode" { return "Menu_General" }
        "Select_Mode_SubMenu" { return "Menu_Mode" }
        "Menu_Wallpaper" { return "Menu_General" }
        "Menu_Wallpaper_Light" { return "Menu_Wallpaper" }
        "Menu_WpMode_L" { return "Menu_Wallpaper_Light" }
        "Menu_WpColorType_L" { return "Menu_Wallpaper_Light" }
        "Menu_Pick_WpWinColor_L" { return "Menu_WpColorType_L" }
        "Menu_WpInterval_L" { return "Menu_Wallpaper_Light" }
        "Menu_Wallpaper_Dark" { return "Menu_Wallpaper" }
        "Menu_WpMode_D" { return "Menu_Wallpaper_Dark" }
        "Menu_WpColorType_D" { return "Menu_Wallpaper_Dark" }
        "Menu_Pick_WpWinColor_D" { return "Menu_WpColorType_D" }
        "Menu_WpInterval_D" { return "Menu_Wallpaper_Dark" }
        "Menu_Accent" { return "Menu_General" }
        "Menu_Accent_Light" { return "Menu_Accent" }
        "Menu_AccMode_L" { return "Menu_Accent_Light" }
        "Menu_Pick_WinColor_L" { return "Menu_Accent_Light" }
        "Menu_Accent_Dark" { return "Menu_Accent" }
        "Menu_AccMode_D" { return "Menu_Accent_Dark" }
        "Menu_Pick_WinColor_D" { return "Menu_Accent_Dark" }
        "Menu_Cursor" { return "Menu_General" }
        "Menu_Pick_Cursor_L" { return "Menu_Cursor" }
        "Menu_Pick_Cursor_D" { return "Menu_Cursor" }
        "Menu_AdjustPriority" { return "Menu_Advanced" }
        "Menu_Select_Prio_Sch" { return "Menu_AdjustPriority" }
        "Menu_Select_Prio_Boot" { return "Menu_AdjustPriority" }
        "Menu_Select_Prio_Sun" { return "Menu_AdjustPriority" }
        "Menu_SystemIntegration" { return "Menu_Advanced" }
        "Menu_CoreSettings" { return "Menu_Advanced" }
        "Menu_Advanced" { return "Main" }
        "Menu_Tools" { return "Main" }
        "Menu_Update" { return "Main" }
        "Menu_About" { return "Main" }
        "Menu_General" { return "Main" }
        default { return "Main" }
    }
}

function Add-Log {
    param(`$Msg)
    if (`$global:logEn -ne 1) { 
        `$global:lastMsg = `$Msg
        return 
    }
    `$time = (Get-Date).ToString("HH:mm:ss")
    `$global:sectionLogs += "[`$time] `$Msg"
    if (`$global:sectionLogs.Count -gt 5) { `$global:sectionLogs = `$global:sectionLogs[-5..-1] }
    try { `$global:sectionLogs | Set-Content `$global:logFile -Force } catch {}
}

function Show-InputScreen {
    param(
        [string]`$Title,
        [string]`$PromptStr,
        [string]`$DefaultValue,
        [string]`$CurrentValue = "",
        [string]`$Format = "",
        [string]`$Description = "",
        [string[]]`$HelpText = @()
    )
    Hide-Loading
    Clear-Host
    Write-Host "`n  `$e[1m`${cHeading}:: Dark Switch CORE ::`$cReset `$cDim(v$appVersion)`$cReset`n"
    
    if (`$global:topNavEn -eq 1) {
        Write-Host "   `$cDim> `$global:breadcrumb > `$Title`$cReset`n"
    }
    
    if (`$Description) { Write-Host "   `$cMain Description : `$cReset`$Description" }
    if (`$CurrentValue) { Write-Host "   `$cMain Current      : `$cYellow`$CurrentValue`$cReset" }
    if (`$DefaultValue) { Write-Host "   `$cMain Default      : `$cDim`$DefaultValue`$cReset" }
    if (`$Format) { Write-Host "   `$cMain Format       : `$cDim`$Format`$cReset" }
    
    if (`$HelpText.Count -gt 0) {
        Write-Host ""
        foreach (`$line in `$HelpText) {
            Write-Host "  `$line"
        }
    }
    
    Write-Host "`n   `$cDim(Press ESC to cancel and return)`$cReset"
    Write-Host "   `$cMain> `${PromptStr}:`$cReset " -NoNewline
    
    `$inputString = ""
    while (`$true) {
        `$k = [Console]::ReadKey(`$true)
        if (`$k.Key -eq 'Escape') {
            return 'ESC_CANCEL'
        } elseif (`$k.Key -eq 'Enter') {
            Write-Host ""
            return `$inputString
        } elseif (`$k.Key -eq 'Backspace') {
            if (`$inputString.Length -gt 0) {
                `$inputString = `$inputString.Substring(0, `$inputString.Length - 1)
                [Console]::Write([char]8)
                [Console]::Write(' ')
                [Console]::Write([char]8)
            }
        } elseif (-not [char]::IsControl(`$k.KeyChar)) {
            `$inputString += `$k.KeyChar
            [Console]::Write(`$k.KeyChar)
        }
    }
}

function Get-TaskAction (`$Type) {
    if (`$Type -eq 'TOGGLE') {
        return New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"`$engineDir\Toggle.vbs`""
    } else {
        `$file = "CoreEngine.ps1"
        `$arg = " `$Type"
        return New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"`$vbs`" `"`$engineDir\`$file`"`$arg"
    }
}

function Get-ValidTime (`$Title, `$Prompt, `$Current, `$Default, `$Desc) {
    while (`$true) {
        `$timeStr = Show-InputScreen -Title `$Title -PromptStr `$Prompt -CurrentValue `$Current -DefaultValue `$Default -Format `$timeHint -Description `$Desc
        if (`$timeStr -eq 'ESC_CANCEL') { return 'ESC_CANCEL' }
        if ([string]::IsNullOrWhiteSpace(`$timeStr)) { return `$Default }
        try { return [datetime]::Parse(`$timeStr).ToString(`$timeFormat) } 
        catch { 
            Write-Host "`n   `$cRed-> Invalid format. Use `$timeHint.`$cReset" 
            Start-Sleep -Seconds 1
        }
    }
}

function Draw-Screen {
    Clear-Host
    Write-Host "`n  `$e[1m`${cHeading}:: Dark Switch CORE ::`$cReset `$cDim(v$appVersion)`$cReset`n"
    
    if (`$global:topNavEn -eq 1) {
        Write-Host "   `$cDim> `$global:breadcrumb >`$cReset`n"
    }

    if (`$global:menuState -eq "Menu_Mode" -and `$global:currentMode -eq "Dynamic Sunrise/sunset sync") {
        Write-Host "   Location:          `$cYellow`$global:locLat, `$global:locLon`$cReset"
        Write-Host "   Today's Sunrise:   `$cYellow`$global:lTime`$cReset"
        Write-Host "   Today's Sunset:    `$cYellow`$global:dTime`$cReset`n"
    }

    # Scrolling viewport logic for large lists like Pick Windows Color
    `$maxItems = 15
    `$startIndex = 0
    `$endIndex = `$global:currentOptions.Count - 1
    
    if (`$global:currentOptions.Count -gt `$maxItems) {
        `$half = [math]::Floor(`$maxItems / 2)
        `$startIndex = `$global:selIndex - `$half
        if (`$startIndex -lt 0) { `$startIndex = 0 }
        `$endIndex = `$startIndex + `$maxItems - 1
        if (`$endIndex -ge `$global:currentOptions.Count) { 
            `$endIndex = `$global:currentOptions.Count - 1
            `$startIndex = `$endIndex - `$maxItems + 1
            if (`$startIndex -lt 0) { `$startIndex = 0 }
        }
    }

    for (`$i = `$startIndex; `$i -le `$endIndex; `$i++) {
        `$opt = `$global:currentOptions[`$i]
        `$valStr = if (`$opt.Value) { " `$cDim=`$cReset " + `$opt.Value } else { "" }
        
        if (`$i -eq `$global:selIndex) {
            Write-Host ("  `$cMain> `$cMain" + `$opt.Label + "`$cReset" + `$valStr)
            if (-not [string]::IsNullOrEmpty(`$opt.Desc)) { Write-Host ("    `$cDim" + `$opt.Desc + "`$cReset") }
        } else {
            Write-Host ("    `$cText" + `$opt.Label + "`$cReset" + `$valStr)
            if (-not [string]::IsNullOrEmpty(`$opt.Desc)) { Write-Host ("    `$cDim" + `$opt.Desc + "`$cReset") }
        }
        if (-not [string]::IsNullOrEmpty(`$opt.Desc) -and `$i -ne `$endIndex) { Write-Host "" }
    }
    
    if (`$global:currentOptions.Count -gt `$maxItems) {
        Write-Host "    `$cDim... (Scroll for more) ...`$cReset"
    }

    Write-Host ""
    
    if (`$global:lastMsg) { 
        Write-Host "`n   `$cGreen>> `$global:lastMsg`$cReset"
        `$global:lastMsg = "" 
    }

    Write-Host ""
    `$global:StatusLineY = [Console]::CursorTop
    if (`$global:isLoading) {
        Write-Host "" 
    }

    `$navHint = "UP/DOWN navigate | ENTER/RIGHT select | ESC/LEFT back/quit"
    Write-Host "`n  `$cDim `$navHint `$cReset`n"

    if (`$global:sectionLogs.Count -gt 0 -and `$global:logEn -eq 1) {
        foreach (`$msg in `$global:sectionLogs) { Write-Host "   `$cDim>> `$msg`$cReset" }
    }
}

function Show-Loading {
    param(`$Msg = "Applying changes")
    `$syncHash.Run = `$false
    [System.Threading.Thread]::Sleep(60)
    `$global:isLoading = `$true
    [console]::CursorVisible = `$false
    Draw-Screen
    `$syncHash.Top = `$global:StatusLineY
    `$syncHash.Msg = `$Msg
    `$syncHash.Run = `$true
}

function Hide-Loading {
    `$syncHash.Run = `$false
    `$global:isLoading = `$false
    [System.Threading.Thread]::Sleep(60)
}

`$runLoop = `$true
`$needsRefresh = `$true
`$renderNeeded = `$true

try {
    Show-Loading "Initializing Core and verifying tasks"

    [console]::CursorVisible = `$false
    while (`$runLoop) {
        if (`$needsRefresh) {
            `$legacyTasks = Get-ScheduledTask -TaskPath `$tPath -ErrorAction SilentlyContinue
            if (-not `$legacyTasks) { `$legacyTasks = @(Get-ScheduledTask -TaskName "DarkSwitch*" -ErrorAction SilentlyContinue) }
            
            `$tLight = `$legacyTasks | Where-Object TaskName -eq "DarkSwitch - Light Mode"
            `$tDark = `$legacyTasks | Where-Object TaskName -eq "DarkSwitch - Dark Mode"
            `$tBoot = `$legacyTasks | Where-Object TaskName -eq "DarkSwitch - Boot Sync"
            `$tSun = `$legacyTasks | Where-Object TaskName -eq "DarkSwitch - Sun Update"

            `$global:lTime = if (`$tLight) { try { [datetime]::Parse(`$tLight.Triggers[0].StartBoundary).ToString(`$timeFormat) } catch { "N/A" } } else { "N/A" }
            `$global:dTime = if (`$tDark) { try { [datetime]::Parse(`$tDark.Triggers[0].StartBoundary).ToString(`$timeFormat) } catch { "N/A" } } else { "N/A" }
            `$tLightState = if (`$tLight) { `$tLight.State } else { 'Disabled' }
            `$tBootState = if (`$tBoot) { `$tBoot.State } else { 'Disabled' }
            
            `$xmlLight = try { Export-ScheduledTask -TaskName "DarkSwitch - Light Mode" -TaskPath `$tPath -ErrorAction Stop | Out-String } catch { `$null }
            `$schPrio = if (`$xmlLight -and `$xmlLight -match '<Priority>\s*(\d+)\s*</Priority>') { `$matches[1] } else { "2" }
            
            `$xmlBoot = try { Export-ScheduledTask -TaskName "DarkSwitch - Boot Sync" -TaskPath `$tPath -ErrorAction Stop | Out-String } catch { `$null }
            `$bootPrio = if (`$xmlBoot -and `$xmlBoot -match '<Priority>\s*(\d+)\s*</Priority>') { `$matches[1] } else { "2" }
            
            `$xmlSun = try { Export-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath `$tPath -ErrorAction Stop | Out-String } catch { `$null }
            `$sunPrio = if (`$xmlSun -and `$xmlSun -match '<Priority>\s*(\d+)\s*</Priority>') { `$matches[1] } else { "2" }
            
            `$isSmHidden = `$false
            if (Test-Path `$smPath) { `$isSmHidden = ((Get-Item `$smPath -Force).Attributes -band [System.IO.FileAttributes]::Hidden) -eq [System.IO.FileAttributes]::Hidden }
            `$scToggle = `$WshShell.CreateShortcut(`$scTogglePath)
            `$hotkey = `$scToggle.Hotkey
            `$hkEnabled = [bool]`$hotkey

            `$bootStatus = if (`$tBootState -ne 'Disabled') { "`$cGreen[ ENABLED ]`$cReset" } else { "`$cRed[ DISABLED ]`$cReset" }
            `$smStatus = if (`$isSmHidden) { "`$cRed[ HIDDEN ]`$cReset" } else { "`$cGreen[ VISIBLE ]`$cReset" }
            `$hkStatus = if (`$hkEnabled) { "`$cGreen[ ENABLED ]`$cReset" } else { "`$cRed[ DISABLED ]`$cReset" }

            `$regPath = "HKCU:\SOFTWARE\DarkSwitch"
            `$regData = Get-ItemProperty `$regPath -ErrorAction SilentlyContinue
            
            `$global:logEn = if (`$regData.LoggingEnabled -ne `$null) { `$regData.LoggingEnabled } else { 0 }
            `$logStatusStr = if (`$global:logEn -eq 1) { "`$cGreen[ ENABLED ]`$cReset" } else { "`$cRed[ DISABLED ]`$cReset" }
            
            `$global:topNavEn = if (`$regData.TopNavEnabled -ne `$null) { `$regData.TopNavEnabled } else { 1 }
            `$navStatusStr = if (`$global:topNavEn -eq 1) { "`$cGreen[ ENABLED ]`$cReset" } else { "`$cRed[ DISABLED ]`$cReset" }
            
            `$global:updMenuEn = if (`$regData.UpdateMenuEnabled -ne `$null) { `$regData.UpdateMenuEnabled } else { 1 }
            `$updStatusStr = if (`$global:updMenuEn -eq 1) { "`$cGreen[ ENABLED ]`$cReset" } else { "`$cRed[ DISABLED ]`$cReset" }

            `$dynSun = if (`$regData.DynamicSun) { `$regData.DynamicSun } else { "N" }
            `$sunTimeVal = if (`$regData.SunTime) { `$regData.SunTime } else { "`$defSun1" }
            `$sunSyncBoot = if (`$regData.SunSyncBoot) { `$regData.SunSyncBoot } else { "Y" }
            `$sunBootStatus = if (`$sunSyncBoot -eq "Y") { "`$cGreen[ ENABLED ]`$cReset" } else { "`$cRed[ DISABLED ]`$cReset" }
            `$global:locLat = if (`$regData.LastLat) { `$regData.LastLat } else { "Unknown" }
            `$global:locLon = if (`$regData.LastLon) { `$regData.LastLon } else { "Unknown" }

            `$global:currentMode = "Off"
            if (`$tLightState -ne 'Disabled') {
                if (`$dynSun -eq "Y") { `$global:currentMode = "Dynamic Sunrise/sunset sync" }
                else { `$global:currentMode = "Scheduled" }
            }
            `$modeColor = if (`$global:currentMode -eq "Off") { `$cRed } elseif (`$global:currentMode -eq "Scheduled") { `$cYellow } else { `$cGreen }
            `$modeDisplay = "`$modeColor[ `$global:currentMode ]`$cReset"

            `$savedKey = if (`$regData.ShortcutKey) { `$regData.ShortcutKey } else { "T" }
            
            # WP En
            `$wpEn = if (`$regData.WallpaperEnabled) { `$regData.WallpaperEnabled } else { 0 }
            `$wpStatusStr = if (`$wpEn -eq 1) { "`$cGreen[ ENABLED ]`$cReset" } else { "`$cRed[ DISABLED ]`$cReset" }
            `$lWall = `$regData.LightWpFile
            `$dWall = `$regData.DarkWpFile
            `$lWallName = if (`$regData.LightWallpaperName) { `$regData.LightWallpaperName } elseif (`$lWall) { [System.IO.Path]::GetFileName(`$lWall) } else { "none" }
            `$dWallName = if (`$regData.DarkWallpaperName) { `$regData.DarkWallpaperName } elseif (`$dWall) { [System.IO.Path]::GetFileName(`$dWall) } else { "none" }
            if (`$lWallName.Length -gt 15) { `$lWallName = `$lWallName.Substring(0,12) + "..." }
            if (`$dWallName.Length -gt 15) { `$dWallName = `$dWallName.Substring(0,12) + "..." }

            # Accent En
            `$accEn = if (`$regData.AccentEnabled) { `$regData.AccentEnabled } else { 0 }
            `$accStatusStr = if (`$accEn -eq 1) { "`$cGreen[ ENABLED ]`$cReset" } else { "`$cRed[ DISABLED ]`$cReset" }
            
            `$lAccMode = if (`$regData.LightAccMode -ne `$null) { `$regData.LightAccMode } else { 0 }
            `$dAccMode = if (`$regData.DarkAccMode -ne `$null) { `$regData.DarkAccMode } else { 0 }
            `$lAccWin = if (`$regData.LightAccWinColor) { `$regData.LightAccWinColor } else { "#0078D4" }
            `$dAccWin = if (`$regData.DarkAccWinColor) { `$regData.DarkAccWinColor } else { "#0078D4" }
            `$lAccCust = if (`$regData.LightAccCustom) { `$regData.LightAccCustom } else { "#0078D4" }
            `$dAccCust = if (`$regData.DarkAccCustom) { `$regData.DarkAccCustom } else { "#0078D4" }

            # Cursor En
            `$curEn = if (`$regData.CursorEnabled) { `$regData.CursorEnabled } else { 0 }
            `$curStatusStr = if (`$curEn -eq 1) { "`$cGreen[ ENABLED ]`$cReset" } else { "`$cRed[ DISABLED ]`$cReset" }
            `$lCur = if (`$regData.LightCursor) { `$regData.LightCursor } else { "Windows Default" }
            `$dCur = if (`$regData.DarkCursor) { `$regData.DarkCursor } else { "Windows Default" }

            `$needsRefresh = `$false
            `$renderNeeded = `$true
        }

        if (`$renderNeeded) {
            Hide-Loading
            `$global:breadcrumb = Get-Breadcrumb
            `$global:currentOptions = @()

            if (`$global:menuState -eq "Main") {
                `$global:currentOptions += @{ Label="Tools"; Value=`$null; Desc="Toggle theme now, Reset Dark Switch, Uninstall Dark Switch"; Action="Menu_Tools" }
                `$global:currentOptions += @{ Label="General Settings"; Value=`$null; Desc="Mode scheduling, Wallpapers, Accent colors"; Action="Menu_General" }
                `$global:currentOptions += @{ Label="Advanced Settings"; Value=`$null; Desc="Priorities, System integrations, Core tweaks"; Action="Menu_Advanced" }
                if (`$global:updMenuEn -eq 1) {
                    `$global:currentOptions += @{ Label="Updates"; Value=`$null; Desc="Check for app updates"; Action="Menu_Update" }
                }
                `$global:currentOptions += @{ Label="About"; Value=`$null; Desc="Dev links and info"; Action="Menu_About" }
                `$global:currentOptions += @{ Label="Exit"; Value=`$null; Desc="Close the core"; Action="Quit" }
            } elseif (`$global:menuState -eq "Menu_General") {
                `$global:currentOptions += @{ Label="Mode switch"; Value=`$null; Desc="Method of switch and scheduling settings"; Action="Menu_Mode" }
                `$global:currentOptions += @{ Label="Wallpaper switch"; Value=`$null; Desc="Configure background wallpapers"; Action="Menu_Wallpaper" }
                `$global:currentOptions += @{ Label="Accent color switch"; Value=`$null; Desc="Configure system accent colors"; Action="Menu_Accent" }
                `$global:currentOptions += @{ Label="Cursor scheme switch"; Value=`$null; Desc="Configure system cursor packs"; Action="Menu_Cursor" }
                `$global:currentOptions += @{ Label="< Back"; Value=`$null; Desc="Return to main menu"; Action="Main" }
            } elseif (`$global:menuState -eq "Menu_Cursor") {
                `$global:currentOptions += @{ Label="Cursor Switch"; Value=`$curStatusStr; Desc="Enable automatic cursor changes"; Action="Toggle_Cursor" }
                if (`$curEn -eq 1) {
                    `$global:currentOptions += @{ Label="Light Mode Cursor"; Value=("" + `$cGreen + `$lCur + `$cReset); Desc="Configure cursor scheme for light mode"; Action="Menu_Pick_Cursor_L" }
                    `$global:currentOptions += @{ Label="Dark Mode Cursor"; Value=("" + `$cGreen + `$dCur + `$cReset); Desc="Configure cursor scheme for dark mode"; Action="Menu_Pick_Cursor_D" }
                }
                `$global:currentOptions += @{ Label="< Back"; Value=`$null; Desc="Return to previous menu"; Action="Menu_General" }
            } elseif (`$global:menuState -in @("Menu_Pick_Cursor_L", "Menu_Pick_Cursor_D")) {
                `$isL = (`$global:menuState -eq "Menu_Pick_Cursor_L")
                `$pMode = if (`$isL) { "L" } else { "D" }
                
                `$global:currentOptions += @{ Label="Windows Default"; Value=`$null; Desc="Standard Windows Cursor"; Action=("Apply_Cursor:" + `$pMode + ":Windows Default") }
                
                `$allSchemes = @()
                
                # Fetch System Schemes (HKLM)
                `$sysSchemesPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\Cursors\Schemes"
                if (Test-Path `$sysSchemesPath) {
                    `$sysSchemes = Get-ItemProperty -Path `$sysSchemesPath -ErrorAction SilentlyContinue
                    if (`$sysSchemes) {
                        foreach (`$prop in `$sysSchemes.psobject.properties) {
                            if (`$prop.Name -notin @("PSPath","PSParentPath","PSChildName","PSDrive","PSProvider")) {
                                if (`$allSchemes -notcontains `$prop.Name) { `$allSchemes += `$prop.Name }
                            }
                        }
                    }
                }

                # Fetch User Schemes (HKCU) - Where custom installers put them
                `$usrSchemesPath = "HKCU:\Control Panel\Cursors\Schemes"
                if (Test-Path `$usrSchemesPath) {
                    `$usrSchemes = Get-ItemProperty -Path `$usrSchemesPath -ErrorAction SilentlyContinue
                    if (`$usrSchemes) {
                        foreach (`$prop in `$usrSchemes.psobject.properties) {
                            if (`$prop.Name -notin @("PSPath","PSParentPath","PSChildName","PSDrive","PSProvider")) {
                                if (`$allSchemes -notcontains `$prop.Name) { `$allSchemes += `$prop.Name }
                            }
                        }
                    }
                }

                # Sort Alphabetically
                `$allSchemes = `$allSchemes | Sort-Object
                
                foreach (`$schemeName in `$allSchemes) {
                    `$global:currentOptions += @{ Label=`$schemeName; Value=`$null; Desc=""; Action=("Apply_Cursor:" + `$pMode + ":" + `$schemeName) }
                }
                
                `$global:currentOptions += @{ Label="< Cancel"; Value=`$null; Desc=""; Action="Menu_Cursor" }
            } elseif (`$global:menuState -eq "Menu_Mode") {
                `$global:currentOptions += @{ Label="Method of Switch"; Value=`$modeDisplay; Desc="Select how Dark Switch schedules themes"; Action="Select_Mode_SubMenu" }
                if (`$global:currentMode -eq "Scheduled") {
                    `$global:currentOptions += @{ Label="Light Mode Time"; Value=("" + `$cYellow + `$global:lTime + `$cReset); Desc="Set the time Light Mode activates"; Action="Set_Light" }
                    `$global:currentOptions += @{ Label="Dark Mode Time"; Value=("" + `$cYellow + `$global:dTime + `$cReset); Desc="Set the time Dark Mode activates"; Action="Set_Dark" }
                } elseif (`$global:currentMode -eq "Dynamic Sunrise/sunset sync") {
                    `$global:currentOptions += @{ Label="Calculation Time"; Value=("" + `$cYellow + `$sunTimeVal + `$cReset); Desc="Time to run the daily sun calculation"; Action="Set_SunTime" }
                    `$global:currentOptions += @{ Label="Sync Sun Times on Boot"; Value=`$sunBootStatus; Desc="Calculate missing sun times at logon"; Action="Toggle_SunBoot" }
                    `$global:currentOptions += @{ Label="Force Update Now"; Value=`$null; Desc="Immediately recalculate and apply sun times"; Action="Force_SunUpdate" }
                }
                `$global:currentOptions += @{ Label="< Back"; Value=`$null; Desc="Return to previous menu"; Action="Menu_General" }
            } elseif (`$global:menuState -eq "Select_Mode_SubMenu") {
                `$global:currentOptions += @{ Label="Off"; Value=`$null; Desc="Disable all automatic scheduling"; Action="Set_Mode_Off" }
                `$global:currentOptions += @{ Label="Scheduled"; Value=`$null; Desc="Switch themes based on static times"; Action="Set_Mode_Scheduled" }
                `$global:currentOptions += @{ Label="Dynamic Sunrise/sunset sync"; Value=`$null; Desc="Automatically switch based on local sun times"; Action="Set_Mode_Dynamic" }
                `$global:currentOptions += @{ Label="< Cancel"; Value=`$null; Desc="Go back without changing"; Action="Menu_Mode" }
            } elseif (`$global:menuState -eq "Menu_Wallpaper") {
                `$global:currentOptions += @{ Label="Wallpaper Switch"; Value=`$wpStatusStr; Desc="Enable automatic wallpaper changes"; Action="Toggle_WP" }
                if (`$wpEn -eq 1) {
                    `$global:currentOptions += @{ Label="Light Mode Wallpaper"; Value=`$null; Desc="Configure background for light mode"; Action="Menu_Wallpaper_Light" }
                    `$global:currentOptions += @{ Label="Dark Mode Wallpaper"; Value=`$null; Desc="Configure background for dark mode"; Action="Menu_Wallpaper_Dark" }
                }
                `$global:currentOptions += @{ Label="< Back"; Value=`$null; Desc="Return to previous menu"; Action="Menu_General" }
            } elseif (`$global:menuState -in @("Menu_Wallpaper_Light", "Menu_Wallpaper_Dark")) {
                `$isL = (`$global:menuState -eq "Menu_Wallpaper_Light")
                `$pMode = if (`$isL) { "L" } else { "D" }
                `$wpMode = if (`$isL) { `$regData.LightWpMode } else { `$regData.DarkWpMode }
                `$wpModeStr = if (`$wpMode -eq 0) { "Picture" } elseif (`$wpMode -eq 1) { "Solid Color" } else { "Slideshow" }
                
                `$global:currentOptions += @{ Label="Mode"; Value=("" + `$cYellow + `$wpModeStr + `$cReset); Desc="Select the type of wallpaper"; Action=("Menu_WpMode_" + `$pMode) }
                
                if (`$wpMode -eq 0) {
                    `$fName = if (`$isL) { `$lWallName } else { `$dWallName }
                    `$global:currentOptions += @{ Label="Choose Image"; Value=("" + `$cGreen + `$fName + `$cReset); Desc="Select a custom wallpaper image"; Action=("Set_WpFile_" + `$pMode) }
                } elseif (`$wpMode -eq 1) {
                    `$col = if (`$isL) { `$regData.LightWpColor } else { `$regData.DarkWpColor }
                    `$cName = Get-WpColorName `$col
                    `$cb = Get-ColorBlock `$col
                    `$global:currentOptions += @{ Label="Choose Solid Color"; Value=("" + `$cb + " " + `$cName); Desc="Select solid color background"; Action=("Menu_WpColorType_" + `$pMode) }
                } elseif (`$wpMode -eq 2) {
                    `$fld = if (`$isL) { `$regData.LightWpFolder } else { `$regData.DarkWpFolder }
                    `$fldDisplay = if ([string]::IsNullOrWhiteSpace(`$fld)) { "Not set" } elseif (`$fld.Length -gt 25) { "..." + `$fld.Substring(`$fld.Length - 22) } else { `$fld }
                    
                    `$tick = if (`$isL) { `$regData.LightWpInterval } else { `$regData.DarkWpInterval }
                    `$tickStr = Get-IntervalString `$tick
                    `$global:currentOptions += @{ Label="Slideshow Folder"; Value=("" + `$cGreen + `$fldDisplay + `$cReset); Desc="Folder containing your slideshow images"; Action=("Set_WpFolder_" + `$pMode) }
                    `$global:currentOptions += @{ Label="Change Interval"; Value=("" + `$cGreen + `$tickStr + `$cReset); Desc="Time between picture changes"; Action=("Menu_WpInterval_" + `$pMode) }
                }
                `$global:currentOptions += @{ Label="< Back"; Value=`$null; Desc="Return to previous menu"; Action="Menu_Wallpaper" }
            } elseif (`$global:menuState -in @("Menu_WpColorType_L", "Menu_WpColorType_D")) {
                `$isL = (`$global:menuState -eq "Menu_WpColorType_L")
                `$pMode = if (`$isL) { "L" } else { "D" }
                `$menuBack = if (`$isL) { "Menu_Wallpaper_Light" } else { "Menu_Wallpaper_Dark" }
                `$global:currentOptions += @{ Label="Windows color"; Value=`$null; Desc="Pick from standard Windows 11 solid colors"; Action=("Menu_Pick_WpWinColor_" + `$pMode) }
                `$global:currentOptions += @{ Label="Custom color"; Value=`$null; Desc="Enter your own HEX color code"; Action=("Set_WpColor_" + `$pMode) }
                `$global:currentOptions += @{ Label="< Cancel"; Value=`$null; Desc=""; Action=`$menuBack }
            } elseif (`$global:menuState -in @("Menu_Pick_WpWinColor_L", "Menu_Pick_WpWinColor_D")) {
                `$isL = (`$global:menuState -eq "Menu_Pick_WpWinColor_L")
                `$pMode = if (`$isL) { "L" } else { "D" }
                `$menuBack = if (`$isL) { "Menu_WpColorType_L" } else { "Menu_WpColorType_D" }
                
                foreach (`$wpCol in `$global:wpSolidColors) {
                    `$hex = `$wpCol.Hex
                    `$name = `$wpCol.Name
                    `$cb = Get-ColorBlock `$hex
                    `$global:currentOptions += @{ Label=`$name; Value=("" + `$cb + " " + `$hex); Desc=""; Action=("Apply_WpWinColor:" + `$pMode + ":" + `$hex) }
                }
                `$global:currentOptions += @{ Label="< Cancel"; Value=`$null; Desc=""; Action=`$menuBack }
            } elseif (`$global:menuState -in @("Menu_WpMode_L", "Menu_WpMode_D")) {
                `$isL = (`$global:menuState -eq "Menu_WpMode_L")
                `$pMode = if (`$isL) { "L" } else { "D" }
                `$menuBack = if (`$isL) { "Menu_Wallpaper_Light" } else { "Menu_Wallpaper_Dark" }
                `$global:currentOptions += @{ Label="Picture"; Value=`$null; Desc="Use a single custom image"; Action=("Apply_WpMode:" + `$pMode + ":0") }
                `$global:currentOptions += @{ Label="Solid Color"; Value=`$null; Desc="Use a static solid color background"; Action=("Apply_WpMode:" + `$pMode + ":1") }
                `$global:currentOptions += @{ Label="Slideshow"; Value=`$null; Desc="Cycle through a folder of images"; Action=("Apply_WpMode:" + `$pMode + ":2") }
                `$global:currentOptions += @{ Label="< Cancel"; Value=`$null; Desc=""; Action=`$menuBack }
            } elseif (`$global:menuState -in @("Menu_WpInterval_L", "Menu_WpInterval_D")) {
                `$isL = (`$global:menuState -eq "Menu_WpInterval_L")
                `$pMode = if (`$isL) { "L" } else { "D" }
                `$menuBack = if (`$isL) { "Menu_Wallpaper_Light" } else { "Menu_Wallpaper_Dark" }
                `$global:currentOptions += @{ Label="1 Minute"; Value=`$null; Desc=""; Action=("Apply_WpTick:" + `$pMode + ":60000") }
                `$global:currentOptions += @{ Label="10 Minutes"; Value=`$null; Desc=""; Action=("Apply_WpTick:" + `$pMode + ":600000") }
                `$global:currentOptions += @{ Label="30 Minutes"; Value=`$null; Desc=""; Action=("Apply_WpTick:" + `$pMode + ":1800000") }
                `$global:currentOptions += @{ Label="1 Hour"; Value=`$null; Desc=""; Action=("Apply_WpTick:" + `$pMode + ":3600000") }
                `$global:currentOptions += @{ Label="6 Hours"; Value=`$null; Desc=""; Action=("Apply_WpTick:" + `$pMode + ":21600000") }
                `$global:currentOptions += @{ Label="1 Day"; Value=`$null; Desc=""; Action=("Apply_WpTick:" + `$pMode + ":86400000") }
                `$global:currentOptions += @{ Label="< Cancel"; Value=`$null; Desc=""; Action=`$menuBack }
            } elseif (`$global:menuState -eq "Menu_Accent") {
                `$global:currentOptions += @{ Label="Accent Color Switch"; Value=`$accStatusStr; Desc="Enable automatic accent changes"; Action="Toggle_Acc" }
                if (`$accEn -eq 1) {
                    `$global:currentOptions += @{ Label="Light Mode Accent Color"; Value=`$null; Desc="Configure accent color for light mode"; Action="Menu_Accent_Light" }
                    `$global:currentOptions += @{ Label="Dark Mode Accent Color"; Value=`$null; Desc="Configure accent color for dark mode"; Action="Menu_Accent_Dark" }
                }
                `$global:currentOptions += @{ Label="< Back"; Value=`$null; Desc="Return to previous menu"; Action="Menu_General" }
            } elseif (`$global:menuState -in @("Menu_Accent_Light", "Menu_Accent_Dark")) {
                `$isL = (`$global:menuState -eq "Menu_Accent_Light")
                `$pMode = if (`$isL) { "L" } else { "D" }
                `$accMode = if (`$isL) { `$lAccMode } else { `$dAccMode }
                `$accModeStr = if (`$accMode -eq 0) { "Automatic" } elseif (`$accMode -eq 1) { "Windows color" } else { "Custom color" }
                
                `$global:currentOptions += @{ Label="Mode"; Value=("" + `$cYellow + `$accModeStr + `$cReset); Desc="Select the type of accent color"; Action=("Menu_AccMode_" + `$pMode) }
                
                if (`$accMode -eq 1) {
                    `$col = if (`$isL) { `$lAccWin } else { `$dAccWin }
                    `$cName = Get-WinColorName `$col
                    `$cb = Get-ColorBlock `$col
                    `$global:currentOptions += @{ Label="Choose Windows Color"; Value=("" + `$cb + " " + `$cName); Desc="Select from pre-defined Windows themes"; Action=("Menu_Pick_WinColor_" + `$pMode) }
                } elseif (`$accMode -eq 2) {
                    `$col = if (`$isL) { `$lAccCust } else { `$dAccCust }
                    `$cb = Get-ColorBlock `$col
                    `$global:currentOptions += @{ Label="Choose Custom Color"; Value=("" + `$cb + " " + `$col); Desc="Enter a custom HEX code"; Action=("Set_Acc_Custom_" + `$pMode) }
                }
                `$global:currentOptions += @{ Label="< Back"; Value=`$null; Desc="Return to previous menu"; Action="Menu_Accent" }
            } elseif (`$global:menuState -in @("Menu_AccMode_L", "Menu_AccMode_D")) {
                `$isL = (`$global:menuState -eq "Menu_AccMode_L")
                `$pMode = if (`$isL) { "L" } else { "D" }
                `$menuBack = if (`$isL) { "Menu_Accent_Light" } else { "Menu_Accent_Dark" }
                `$global:currentOptions += @{ Label="Automatic"; Value=`$null; Desc="Match accent to current wallpaper automatically"; Action=("Apply_AccMode:" + `$pMode + ":0") }
                `$global:currentOptions += @{ Label="Windows color"; Value=`$null; Desc="Pick from standard Windows 11 colors"; Action=("Apply_AccMode:" + `$pMode + ":1") }
                `$global:currentOptions += @{ Label="Custom color"; Value=`$null; Desc="Enter your own HEX color code"; Action=("Apply_AccMode:" + `$pMode + ":2") }
                `$global:currentOptions += @{ Label="< Cancel"; Value=`$null; Desc=""; Action=`$menuBack }
            } elseif (`$global:menuState -in @("Menu_Pick_WinColor_L", "Menu_Pick_WinColor_D")) {
                `$isL = (`$global:menuState -eq "Menu_Pick_WinColor_L")
                `$pMode = if (`$isL) { "L" } else { "D" }
                `$menuBack = if (`$isL) { "Menu_Accent_Light" } else { "Menu_Accent_Dark" }
                
                foreach (`$winCol in `$global:winColors) {
                    `$hex = `$winCol.Hex
                    `$name = `$winCol.Name
                    `$cb = Get-ColorBlock `$hex
                    `$global:currentOptions += @{ Label=`$name; Value=("" + `$cb + " " + `$hex); Desc=""; Action=("Apply_WinColor:" + `$pMode + ":" + `$hex) }
                }
                `$global:currentOptions += @{ Label="< Cancel"; Value=`$null; Desc=""; Action=`$menuBack }
            } elseif (`$global:menuState -eq "Menu_Advanced") {
                `$global:currentOptions += @{ Label="Adjust priority"; Value=`$null; Desc="Settings related to execution priority"; Action="Menu_AdjustPriority" }
                `$global:currentOptions += @{ Label="System integration"; Value=`$null; Desc="Boot sync, start menu icons, toggle key"; Action="Menu_SystemIntegration" }
                `$global:currentOptions += @{ Label="Core settings"; Value=`$null; Desc="Turn on/off logging and other core features"; Action="Menu_CoreSettings" }
                `$global:currentOptions += @{ Label="< Back"; Value=`$null; Desc="Return to main menu"; Action="Main" }
            } elseif (`$global:menuState -eq "Menu_AdjustPriority") {
                `$global:currentOptions += @{ Label="Schedule Priority"; Value=("" + `$cYellow + `$schPrio + `$cReset); Desc="Change the process priority of schedule trigger"; Action="Menu_Select_Prio_Sch" }
                `$global:currentOptions += @{ Label="Boot Sync Priority"; Value=("" + `$cYellow + `$bootPrio + `$cReset); Desc="Change the process priority of logon trigger"; Action="Menu_Select_Prio_Boot" }
                if (`$global:currentMode -eq "Dynamic Sunrise/sunset sync") {
                    `$global:currentOptions += @{ Label="Dynamic Calculator Priority"; Value=("" + `$cYellow + `$sunPrio + `$cReset); Desc="Change the priority of the Sun update task"; Action="Menu_Select_Prio_Sun" }
                }
                `$global:currentOptions += @{ Label="< Back"; Value=`$null; Desc="Return to previous menu"; Action="Menu_Advanced" }
            } elseif (`$global:menuState -in @("Menu_Select_Prio_Sch", "Menu_Select_Prio_Boot", "Menu_Select_Prio_Sun")) {
                `$prioType = if (`$global:menuState -eq "Menu_Select_Prio_Sch") { "Sch" } elseif (`$global:menuState -eq "Menu_Select_Prio_Boot") { "Boot" } else { "Sun" }
                
                `$global:currentOptions += @{ Label="0 (Real-time)"; Value=`$null; Desc=""; Action=("Apply_Prio:" + `$prioType + ":0") }
                `$global:currentOptions += @{ Label="1 (High)"; Value=`$null; Desc=""; Action=("Apply_Prio:" + `$prioType + ":1") }
                `$global:currentOptions += @{ Label="2 (Above Normal) [Recommended]"; Value=`$null; Desc=""; Action=("Apply_Prio:" + `$prioType + ":2") }
                `$global:currentOptions += @{ Label="3 (Above Normal)"; Value=`$null; Desc=""; Action=("Apply_Prio:" + `$prioType + ":3") }
                `$global:currentOptions += @{ Label="4 (Normal)"; Value=`$null; Desc=""; Action=("Apply_Prio:" + `$prioType + ":4") }
                `$global:currentOptions += @{ Label="5 / 6 (Below Normal)"; Value=`$null; Desc=""; Action=("Apply_Prio:" + `$prioType + ":6") }
                `$global:currentOptions += @{ Label="7 (Task Default)"; Value=`$null; Desc=""; Action=("Apply_Prio:" + `$prioType + ":7") }
                `$global:currentOptions += @{ Label="8 / 9 (Low)"; Value=`$null; Desc=""; Action=("Apply_Prio:" + `$prioType + ":8") }
                `$global:currentOptions += @{ Label="10 (Idle)"; Value=`$null; Desc=""; Action=("Apply_Prio:" + `$prioType + ":10") }
                `$global:currentOptions += @{ Label="< Cancel"; Value=`$null; Desc=""; Action="Menu_AdjustPriority" }
            } elseif (`$global:menuState -eq "Menu_SystemIntegration") {
                `$global:currentOptions += @{ Label="Boot Sync State"; Value=`$bootStatus; Desc="Enable/Disable theming sync upon logon"; Action="Toggle_Boot" }
                `$global:currentOptions += @{ Label="Start Menu Icons"; Value=`$smStatus; Desc="Hide or Show app shortcuts in start menu"; Action="Toggle_Sm" }
                `$global:currentOptions += @{ Label="Quick Toggle Key"; Value=`$hkStatus; Desc="Enable keyboard shortcut (Ctrl+Alt+`$savedKey)"; Action="Toggle_Hk" }
                if (`$hkEnabled) { `$global:currentOptions += @{ Label="Change Shortcut Key"; Value=`$null; Desc="Bind a new key letter to Ctrl+Alt+?"; Action="Change_Hk" } }
                `$global:currentOptions += @{ Label="< Back"; Value=`$null; Desc="Return to previous menu"; Action="Menu_Advanced" }
            } elseif (`$global:menuState -eq "Menu_CoreSettings") {
                `$global:currentOptions += @{ Label="Toggle Session Logging"; Value=`$logStatusStr; Desc="Enable or disable the core session logs"; Action="Toggle_Logging" }
                `$global:currentOptions += @{ Label="Top Navigation Bar"; Value=`$navStatusStr; Desc="Show or hide the breadcrumb navigation bar on top"; Action="Toggle_TopNav" }
                `$global:currentOptions += @{ Label="Update Menu"; Value=`$updStatusStr; Desc="Show or hide the Updates option from the main menu"; Action="Toggle_UpdateMenu" }
                `$global:currentOptions += @{ Label="< Back"; Value=`$null; Desc="Return to previous menu"; Action="Menu_Advanced" }
            } elseif (`$global:menuState -eq "Menu_Tools") {
                `$global:currentOptions += @{ Label="Toggle Theme Now"; Value=`$null; Desc="Instantly switch between Light and Dark mode"; Action="Do_Toggle" }
                `$global:currentOptions += @{ Label="Reset Dark Switch"; Value=`$null; Desc="Restore settings to default and recreate tasks"; Action="Reset_DarkSwitch" }
                `$global:currentOptions += @{ Label="Uninstall Dark Switch"; Value=`$null; Desc="Completely remove Dark Switch from your system"; Action="Uninstall_DarkSwitch" }
                `$global:currentOptions += @{ Label="< Back"; Value=`$null; Desc="Return to main menu"; Action="Main" }
            } elseif (`$global:menuState -eq "Menu_Update") {
                `$global:currentOptions += @{ Label="Check for Updates"; Value=`$null; Desc="Fetch the latest features from GitHub"; Action="Update_Check" }
                `$global:currentOptions += @{ Label="< Back"; Value=`$null; Desc="Return to main menu"; Action="Main" }
            } elseif (`$global:menuState -eq "Menu_About") {
                `$global:currentOptions += @{ Label="Developer GitHub"; Value=`$null; Desc="Open Developer profile in browser"; Action="Open_Dev" }
                `$global:currentOptions += @{ Label="Developer Website"; Value=`$null; Desc="Visit the Developer's Portfolio Website"; Action="Open_DevWeb" }
                `$global:currentOptions += @{ Label="Project Repository"; Value=`$null; Desc="Open Project Repo in browser"; Action="Open_Proj" }
                `$global:currentOptions += @{ Label="More Projects"; Value=`$null; Desc="Browse all developer repositories on GitHub"; Action="Open_Repos" }
                `$global:currentOptions += @{ Label="< Back"; Value=`$null; Desc="Return to main menu"; Action="Main" }
            }

            if (`$global:selIndex -ge `$global:currentOptions.Count) { `$global:selIndex = `$global:currentOptions.Count - 1 }
            if (`$global:selIndex -lt 0) { `$global:selIndex = 0 }

            Draw-Screen
            `$renderNeeded = `$false
        }

        while (-not [System.Console]::KeyAvailable) { Start-Sleep -Milliseconds 50 }
        `$key = [System.Console]::ReadKey(`$true)

        if (`$key.KeyChar -eq 'q' -or `$key.KeyChar -eq 'Q') { `$runLoop = `$false; continue }

        `$k = `$key.Key.ToString()

        if (`$k -eq 'UpArrow') { 
            `$global:selIndex--
            if (`$global:selIndex -lt 0) { `$global:selIndex = `$global:currentOptions.Count - 1 }
            `$renderNeeded = `$true 
        }
        elseif (`$k -eq 'DownArrow') { 
            `$global:selIndex++
            if (`$global:selIndex -ge `$global:currentOptions.Count) { `$global:selIndex = 0 }
            `$renderNeeded = `$true 
        }
        elseif (`$k -eq 'LeftArrow' -or `$k -eq 'Backspace' -or `$k -eq 'Escape') { 
            if (`$global:menuState -eq "Main") {
                if (`$k -eq 'Escape') { `$runLoop = `$false }
            } else { 
                `$global:menuState = Get-BackState `$global:menuState
                `$global:selIndex = 0
                `$renderNeeded = `$true 
            } 
        }
        elseif (`$k -eq 'Enter' -or `$k -eq 'RightArrow') {
            `$action = `$global:currentOptions[`$global:selIndex].Action
            if (`$action -like "Menu_*" -or `$action -like "Select_*" -or `$action -eq "Main") {
                `$global:menuState = `$action
                `$global:selIndex = 0
                `$renderNeeded = `$true
            } elseif (`$action -like "Apply_Prio:*") {
                `$parts = `$action.Split(':')
                `$pType = `$parts[1]
                `$newPrio = `$parts[2]
                Show-Loading "Updating priorities"
                if (`$pType -eq "Sch") {
                    foreach (`$t in @("DarkSwitch - Light Mode", "DarkSwitch - Dark Mode")) {
                        `$xml = try { Export-ScheduledTask -TaskName `$t -TaskPath `$tPath -ErrorAction Stop | Out-String } catch { `$null }
                        if (`$xml) {
                            if (`$xml -match '<Priority>\s*\d+\s*</Priority>') {
                                `$xml = `$xml -replace '<Priority>\s*\d+\s*</Priority>', "<Priority>`$newPrio</Priority>"
                            } else {
                                `$xml = `$xml -replace '</Settings>', "  <Priority>`$newPrio</Priority>`n  </Settings>"
                            }
                            try { Register-ScheduledTask -TaskName `$t -TaskPath `$tPath -Xml `$xml -Force -User `$env:USERNAME -ErrorAction Stop | Out-Null } catch {}
                        }
                    }
                    Add-Log "Scheduled Sync priority updated to `$newPrio"
                } elseif (`$pType -eq "Boot") {
                    `$xml = try { Export-ScheduledTask -TaskName "DarkSwitch - Boot Sync" -TaskPath `$tPath -ErrorAction Stop | Out-String } catch { `$null }
                    if (`$xml) {
                        if (`$xml -match '<Priority>\s*\d+\s*</Priority>') {
                            `$xml = `$xml -replace '<Priority>\s*\d+\s*</Priority>', "<Priority>`$newPrio</Priority>"
                        } else {
                            `$xml = `$xml -replace '</Settings>', "  <Priority>`$newPrio</Priority>`n  </Settings>"
                        }
                        try { Register-ScheduledTask -TaskName "DarkSwitch - Boot Sync" -TaskPath `$tPath -Xml `$xml -Force -User `$env:USERNAME -ErrorAction Stop | Out-Null } catch {}
                    }
                    Add-Log "Boot Sync priority updated to `$newPrio"
                } elseif (`$pType -eq "Sun") {
                    `$xml = try { Export-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath `$tPath -ErrorAction Stop | Out-String } catch { `$null }
                    if (`$xml) {
                        if (`$xml -match '<Priority>\s*\d+\s*</Priority>') {
                            `$xml = `$xml -replace '<Priority>\s*\d+\s*</Priority>', "<Priority>`$newPrio</Priority>"
                        } else {
                            `$xml = `$xml -replace '</Settings>', "  <Priority>`$newPrio</Priority>`n  </Settings>"
                        }
                        try { Register-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath `$tPath -Xml `$xml -Force -User `$env:USERNAME -ErrorAction Stop | Out-Null } catch {}
                    }
                    Add-Log "Dynamic Calculator priority updated to `$newPrio"
                }
                `$global:menuState = "Menu_AdjustPriority"
                `$global:selIndex = 0
                `$needsRefresh = `$true
            } elseif (`$action -like "Apply_WpMode:*") {
                `$parts = `$action.Split(':')
                `$pMode = `$parts[1]
                `$newMode = [int]`$parts[2]
                Show-Loading "Updating wallpaper mode"
                `$keyName = if (`$pMode -eq 'L') { "LightWpMode" } else { "DarkWpMode" }
                Set-ConfigValue `$keyName `$newMode "DWord"
                
                `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                if ((`$pMode -eq 'L' -and `$currApp -eq 1) -or (`$pMode -eq 'D' -and `$currApp -eq 0)) {
                    [DarkSwitch.Engine]::RefreshCurrent() 
                }
                
                `$global:menuState = if (`$pMode -eq 'L') { "Menu_Wallpaper_Light" } else { "Menu_Wallpaper_Dark" }
                `$global:selIndex = 0
                `$needsRefresh = `$true
            } elseif (`$action -like "Apply_WpTick:*") {
                `$parts = `$action.Split(':')
                `$pMode = `$parts[1]
                `$newTick = [int]`$parts[2]
                Show-Loading "Updating slideshow interval"
                `$keyName = if (`$pMode -eq 'L') { "LightWpInterval" } else { "DarkWpInterval" }
                Set-ConfigValue `$keyName `$newTick "DWord"
                
                `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                if ((`$pMode -eq 'L' -and `$currApp -eq 1) -or (`$pMode -eq 'D' -and `$currApp -eq 0)) {
                    [DarkSwitch.Engine]::RefreshCurrent() 
                }
                
                `$global:menuState = if (`$pMode -eq 'L') { "Menu_Wallpaper_Light" } else { "Menu_Wallpaper_Dark" }
                `$global:selIndex = 0
                `$needsRefresh = `$true
            } elseif (`$action -like "Apply_WpWinColor:*") {
                `$parts = `$action.Split(':')
                `$pMode = `$parts[1]
                `$newHex = `$parts[2]
                Show-Loading "Updating Windows solid color"
                
                `$keyName = if (`$pMode -eq 'L') { "LightWpColor" } else { "DarkWpColor" }
                Set-ConfigValue `$keyName `$newHex "String"
                
                `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                if ((`$pMode -eq 'L' -and `$currApp -eq 1) -or (`$pMode -eq 'D' -and `$currApp -eq 0)) {
                    [DarkSwitch.Engine]::RefreshCurrent() 
                }
                
                `$global:menuState = if (`$pMode -eq 'L') { "Menu_Wallpaper_Light" } else { "Menu_Wallpaper_Dark" }
                `$global:selIndex = 0
                `$needsRefresh = `$true
            } elseif (`$action -like "Apply_AccMode:*") {
                `$parts = `$action.Split(':')
                `$pMode = `$parts[1]
                `$newMode = [int]`$parts[2]
                Show-Loading "Updating accent mode"
                `$keyName = if (`$pMode -eq 'L') { "LightAccMode" } else { "DarkAccMode" }
                Set-ConfigValue `$keyName `$newMode "DWord"
                
                `$finalHex = "auto"
                if (`$newMode -eq 1) { `$finalHex = if (`$pMode -eq 'L') { `$lAccWin } else { `$dAccWin } }
                elseif (`$newMode -eq 2) { `$finalHex = if (`$pMode -eq 'L') { `$lAccCust } else { `$dAccCust } }
                
                `$accKeyName = if (`$pMode -eq 'L') { "LightAccent" } else { "DarkAccent" }
                Set-ConfigValue `$accKeyName `$finalHex "String"
                
                `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                if ((`$pMode -eq 'L' -and `$currApp -eq 1) -or (`$pMode -eq 'D' -and `$currApp -eq 0)) {
                    [DarkSwitch.Engine]::RefreshCurrent() 
                }
                
                `$global:menuState = if (`$pMode -eq 'L') { "Menu_Accent_Light" } else { "Menu_Accent_Dark" }
                `$global:selIndex = 0
                `$needsRefresh = `$true
            } elseif (`$action -like "Apply_WinColor:*") {
                `$parts = `$action.Split(':')
                `$pMode = `$parts[1]
                `$newHex = `$parts[2]
                Show-Loading "Updating Windows accent color"
                
                `$keyName = if (`$pMode -eq 'L') { "LightAccWinColor" } else { "DarkAccWinColor" }
                Set-ConfigValue `$keyName `$newHex "String"
                
                `$accMode = if (`$pMode -eq 'L') { `$lAccMode } else { `$dAccMode }
                if (`$accMode -eq 1) {
                    `$accKeyName = if (`$pMode -eq 'L') { "LightAccent" } else { "DarkAccent" }
                    Set-ConfigValue `$accKeyName `$newHex "String"
                    `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                    if ((`$pMode -eq 'L' -and `$currApp -eq 1) -or (`$pMode -eq 'D' -and `$currApp -eq 0)) {
                        [DarkSwitch.Engine]::RefreshCurrent() 
                    }
                }
                
                `$global:menuState = if (`$pMode -eq 'L') { "Menu_Accent_Light" } else { "Menu_Accent_Dark" }
                `$global:selIndex = 0
                `$needsRefresh = `$true
            } elseif (`$action -like "Apply_Cursor:*") {
                `$parts = `$action.Split(':', 3)
                `$pMode = `$parts[1]
                `$newCur = `$parts[2]
                Show-Loading "Updating Cursor Scheme"
                
                `$keyName = if (`$pMode -eq 'L') { "LightCursor" } else { "DarkCursor" }
                Set-ConfigValue `$keyName `$newCur "String"
                
                `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                if ((`$pMode -eq 'L' -and `$currApp -eq 1) -or (`$pMode -eq 'D' -and `$currApp -eq 0)) {
                    [DarkSwitch.Engine]::RefreshCurrent() 
                }
                
                Add-Log "Cursor Scheme updated to `$newCur"
                `$global:menuState = "Menu_Cursor"
                `$global:selIndex = 0
                `$needsRefresh = `$true
            } elseif (`$action -eq "Quit") {
                `$runLoop = `$false
            } else {
                [console]::CursorVisible = `$true
                switch (`$action) {
                    "Set_Mode_Off" {
                        Show-Loading "Disabling automation"
                        try { Disable-ScheduledTask -TaskName "DarkSwitch - Light Mode" -TaskPath `$tPath -ErrorAction Stop | Out-Null } catch {}
                        try { Disable-ScheduledTask -TaskName "DarkSwitch - Dark Mode" -TaskPath `$tPath -ErrorAction Stop | Out-Null } catch {}
                        try { Disable-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath `$tPath -ErrorAction Stop | Out-Null } catch {}
                        Set-ConfigValue "DynamicSun" "N"
                        Add-Log "Auto switching disabled (Off)."
                        `$global:menuState = "Menu_Mode"
                        `$global:selIndex = 0
                        `$needsRefresh = `$true
                    }
                    "Set_Mode_Scheduled" {
                        Show-Loading "Enabling scheduled mode"
                        try { Disable-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath `$tPath -ErrorAction Stop | Out-Null } catch {}
                        Set-ConfigValue "DynamicSun" "N"
                        
                        `$lTimeConf = if (`$regData.LightTime) { `$regData.LightTime } else { `$defLight }
                        `$dTimeConf = if (`$regData.DarkTime) { `$regData.DarkTime } else { `$defDark }

                        `$actSyncLight = Get-TaskAction "SYNC_LIGHT"
                        `$actSyncDark  = Get-TaskAction "SYNC_DARK"

                        try { `$ptL = Get-Date `$lTimeConf } catch { `$ptL = (Get-Date).Date.AddHours(7) }
                        try {
                            `$tL = Get-ScheduledTask -TaskName "DarkSwitch - Light Mode" -TaskPath `$tPath -ErrorAction Stop
                            `$tL.Triggers[0].StartBoundary = `$ptL.ToString("yyyy-MM-ddTHH:mm:ss")
                            `$tL | Set-ScheduledTask -User `$env:USERNAME -ErrorAction Stop | Out-Null
                        } catch {
                            `$trigL = New-ScheduledTaskTrigger -Daily -At `$ptL
                            try { Register-ScheduledTask -TaskName "DarkSwitch - Light Mode" -TaskPath `$tPath -Action `$actSyncLight -Trigger `$trigL -Principal `$p -Force -ErrorAction Stop | Out-Null } catch {}
                        }

                        try { `$ptD = Get-Date `$dTimeConf } catch { `$ptD = (Get-Date).Date.AddHours(19) }
                        try {
                            `$tD = Get-ScheduledTask -TaskName "DarkSwitch - Dark Mode" -TaskPath `$tPath -ErrorAction Stop
                            `$tD.Triggers[0].StartBoundary = `$ptD.ToString("yyyy-MM-ddTHH:mm:ss")
                            `$tD | Set-ScheduledTask -User `$env:USERNAME -ErrorAction Stop | Out-Null
                        } catch {
                            `$trigD = New-ScheduledTaskTrigger -Daily -At `$ptD
                            try { Register-ScheduledTask -TaskName "DarkSwitch - Dark Mode" -TaskPath `$tPath -Action `$actSyncDark -Trigger `$trigD -Principal `$p -Force -ErrorAction Stop | Out-Null } catch {}
                        }

                        try { Enable-ScheduledTask -TaskName "DarkSwitch - Light Mode" -TaskPath `$tPath -ErrorAction Stop | Out-Null } catch {}
                        try { Enable-ScheduledTask -TaskName "DarkSwitch - Dark Mode" -TaskPath `$tPath -ErrorAction Stop | Out-Null } catch {}
                        
                        Start-Process -FilePath "wscript.exe" -ArgumentList ('"{0}" "{1}\CoreEngine.ps1" SYNC' -f `$vbs, `$engineDir) -WindowStyle Hidden -ErrorAction SilentlyContinue
                        
                        Add-Log "Mode set to Scheduled. Original times restored & synced."
                        `$global:menuState = "Menu_Mode"
                        `$global:selIndex = 0
                        `$needsRefresh = `$true
                    }
                    "Set_Light" {
                        `$newTime = Get-ValidTime "Light Mode Time" "Enter Light Mode Time" `$global:lTime `$defLight "Set the specific time when Light Mode should activate."
                        if (`$newTime -eq 'ESC_CANCEL') { Add-Log "Cancelled."; `$needsRefresh = `$true; break }
                        Show-Loading "Updating Light Time"
                        Set-ConfigValue "LightTime" `$newTime
                        try {
                            `$pt = Get-Date `$newTime
                            `$tLight = Get-ScheduledTask -TaskName "DarkSwitch - Light Mode" -TaskPath `$tPath -ErrorAction Stop
                            `$tLight.Triggers[0].StartBoundary = `$pt.ToString("yyyy-MM-ddTHH:mm:ss")
                            `$tLight | Set-ScheduledTask -User `$env:USERNAME -ErrorAction Stop | Out-Null
                            
                            Start-Process -FilePath "wscript.exe" -ArgumentList ('"{0}" "{1}\CoreEngine.ps1" SYNC' -f `$vbs, `$engineDir) -WindowStyle Hidden -ErrorAction SilentlyContinue
                            
                            Add-Log "Light Mode time updated to `$newTime and synced."
                        } catch { Add-Log "Failed to update Light Mode trigger." }
                        `$needsRefresh = `$true
                    }
                    "Set_Dark" {
                        `$newTime = Get-ValidTime "Dark Mode Time" "Enter Dark Mode Time" `$global:dTime `$defDark "Set the specific time when Dark Mode should activate."
                        if (`$newTime -eq 'ESC_CANCEL') { Add-Log "Cancelled."; `$needsRefresh = `$true; break }
                        Show-Loading "Updating Dark Time"
                        Set-ConfigValue "DarkTime" `$newTime
                        try {
                            `$pt = Get-Date `$newTime
                            `$tDark = Get-ScheduledTask -TaskName "DarkSwitch - Dark Mode" -TaskPath `$tPath -ErrorAction Stop
                            `$tDark.Triggers[0].StartBoundary = `$pt.ToString("yyyy-MM-ddTHH:mm:ss")
                            `$tDark | Set-ScheduledTask -User `$env:USERNAME -ErrorAction Stop | Out-Null
                            
                            Start-Process -FilePath "wscript.exe" -ArgumentList ('"{0}" "{1}\CoreEngine.ps1" SYNC' -f `$vbs, `$engineDir) -WindowStyle Hidden -ErrorAction SilentlyContinue
                            
                            Add-Log "Dark Mode time updated to `$newTime and synced."
                        } catch { Add-Log "Failed to update Dark Mode trigger." }
                        `$needsRefresh = `$true
                    }
                    "Set_Mode_Dynamic" {
                        `$locErr = `$false
                        `$consentGranted = (`$regData.LocationConsent -eq "Y")
                        if (-not `$consentGranted) {
                            `$consentAns = Show-InputScreen -Title "Location Consent" -PromptStr "Do you consent to allow Dark Switch to access your location offline?" -CurrentValue "No" -DefaultValue "No" -Format "Y/N" -Description "Allow Dark Switch to automatically compute precise, local sunrise and sunset times." -HelpText @(
                                " `$cYellow[!] LOCATION CONSENT REQUIRED`$cReset",
                                " Dark Switch uses the Windows Location API offline on your machine.",
                                " Your location coordinates are strictly stored locally and NEVER transmitted."
                            )
                            if (`$consentAns -eq 'ESC_CANCEL') {
                                Add-Log "Dynamic Mode activation cancelled."
                                `$global:menuState = "Menu_Mode"
                                `$global:selIndex = 0
                                `$needsRefresh = `$true
                                break
                            }
                            if (`$consentAns -match '^[Yy]') {
                                Set-ConfigValue "LocationConsent" "Y"
                                `$regData = Get-ItemProperty "HKCU:\SOFTWARE\DarkSwitch" -ErrorAction SilentlyContinue
                            } else {
                                Add-Log "Dynamic Mode activation cancelled: Location consent denied."
                                `$global:menuState = "Menu_Mode"
                                `$global:selIndex = 0
                                `$needsRefresh = `$true
                                break
                            }
                        }

                        if (-not `$regData.LastLat -or -not `$regData.LastLon) {
                            Add-Type -AssemblyName System.Device -ErrorAction SilentlyContinue
                            try {
                                Show-Loading "Fetching Location Services"
                                `$w = New-Object System.Device.Location.GeoCoordinateWatcher([System.Device.Location.GeoPositionAccuracy]::High)
                                `$w.Start()
                                `$t = 15; while ((`$w.Status -ne 'Ready' -or `$w.Position.Location.IsUnknown) -and (`$t -gt 0)) { Start-Sleep -Seconds 1; `$t-- }
                                if (-not `$w.Position.Location.IsUnknown) {
                                    Set-ConfigValue "LastLat" `$w.Position.Location.Latitude.ToString([System.Globalization.CultureInfo]::InvariantCulture)
                                    Set-ConfigValue "LastLon" `$w.Position.Location.Longitude.ToString([System.Globalization.CultureInfo]::InvariantCulture)
                                } else {
                                    `$latIn = Show-InputScreen -Title "Manual Location Entry" -PromptStr "Enter Latitude" -CurrentValue "" -DefaultValue "" -Format "Decimal (e.g., 40.7128)" -Description "Latitude coordinate for Sun Sync calculations." -HelpText @(
                                        " `$cYellow[!] Windows Location Services failed to auto-detect your location.`$cReset",
                                        " `$cDim> Please enter your coordinates manually to enable Sun Sync.`$cReset",
                                        " `$cDim> (You can find these on Google Maps by right-clicking your location)`$cReset"
                                    )
                                    if (`$latIn -eq 'ESC_CANCEL') { 
                                        `$locErr = `$true 
                                    } else {
                                        `$lonIn = Show-InputScreen -Title "Manual Location Entry" -PromptStr "Enter Longitude" -CurrentValue "" -DefaultValue "" -Format "Decimal (e.g., -74.0060)" -Description "Longitude coordinate for Sun Sync calculations." -HelpText @(" Latitude entered: `$cYellow`$latIn`$cReset")
                                        if (`$lonIn -eq 'ESC_CANCEL') {
                                            `$locErr = `$true
                                        } else {
                                            try {
                                                `$parsedLat = [double]::Parse((`$latIn -replace ',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
                                                `$parsedLon = [double]::Parse((`$lonIn -replace ',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
                                                Set-ConfigValue "LastLat" `$parsedLat.ToString([System.Globalization.CultureInfo]::InvariantCulture)
                                                Set-ConfigValue "LastLon" `$parsedLon.ToString([System.Globalization.CultureInfo]::InvariantCulture)
                                            } catch { `$locErr = `$true }
                                        }
                                    }
                                }
                                `$w.Stop()
                            } catch { `$locErr = `$true }
                        }
                        
                        if (`$locErr) {
                            Add-Log "Failed to fetch Location Services offline. Reverting to Scheduled Mode."
                            try { Enable-ScheduledTask -TaskName "DarkSwitch - Light Mode" -TaskPath `$tPath -ErrorAction Stop | Out-Null } catch {}
                            try { Enable-ScheduledTask -TaskName "DarkSwitch - Dark Mode" -TaskPath `$tPath -ErrorAction Stop | Out-Null } catch {}
                            try { Disable-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath `$tPath -ErrorAction Stop | Out-Null } catch {}
                            Set-ConfigValue "DynamicSun" "N"
                        } else {
                            Show-Loading "Enabling Sun Sync"
                            try { Enable-ScheduledTask -TaskName "DarkSwitch - Light Mode" -TaskPath `$tPath -ErrorAction Stop | Out-Null } catch {}
                            try { Enable-ScheduledTask -TaskName "DarkSwitch - Dark Mode" -TaskPath `$tPath -ErrorAction Stop | Out-Null } catch {}
                            
                            `$sunTaskExists = `$false
                            try { `$null = Get-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath `$tPath -ErrorAction Stop; `$sunTaskExists = `$true } catch {}

                            if (-not `$sunTaskExists) {
                                `$safeTime = if ([string]::IsNullOrWhiteSpace(`$regData.SunTime)) { `$defSun1 } else { `$regData.SunTime.Trim() }
                                try { `$pt = Get-Date `$safeTime } catch { `$pt = (Get-Date).Date }
                                `$trigs = @(New-ScheduledTaskTrigger -Daily -At `$pt)
                                if (`$sunSyncBoot -eq "Y") { `$trigs += New-ScheduledTaskTrigger -AtLogOn }
                                
                                try {
                                    `$hasWT = (Test-Path "`$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe") -or [bool](Get-Item "`$env:windir\System32\wt.exe" -ErrorAction SilentlyContinue)
                                    if (`$hasWT) {
                                        `$actSun = New-ScheduledTaskAction -Execute "wt.exe" -Argument ('-w hidden powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}\CoreEngine.ps1" SUN' -f `$engineDir)
                                    } else {
                                        `$actSun = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ('-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}\CoreEngine.ps1" SUN' -f `$engineDir)
                                    }
                                    `$taskSun = New-ScheduledTask -Action `$actSun -Principal `$p -Trigger `$trigs -Settings `$settings
                                    Register-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath `$tPath -InputObject `$taskSun -Force -ErrorAction Stop | Out-Null
                                    if (`$sunSyncBoot -eq "Y") {
                                        `$xmlSun = try { (Export-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath `$tPath -ErrorAction Stop) -replace '</Triggers>', '<SessionStateChangeTrigger><StateChange>SessionUnlock</StateChange></SessionStateChangeTrigger></Triggers>' } catch { `$null }
                                        if (`$xmlSun) { try { Register-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath `$tPath -Xml `$xmlSun -Force -User `$env:USERNAME -ErrorAction Stop | Out-Null } catch {} }
                                    }
                                } catch {}
                            } else {
                                try { Enable-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath `$tPath -ErrorAction Stop | Out-Null } catch {}
                            }

                            Set-ConfigValue "DynamicSun" "Y"
                            
                            try {
                                `$lat = (Get-ItemProperty `$regPath -ErrorAction SilentlyContinue).LastLat
                                `$lon = (Get-ItemProperty `$regPath -ErrorAction SilentlyContinue).LastLon
                                if (`$lat -ne `$null -and `$lon -ne `$null) {
                                    `$latStr = `$lat.ToString()
                                    `$lonStr = `$lon.ToString()
                                    `$latD = [double]::Parse(`$latStr.Replace(',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
                                    `$lonD = [double]::Parse(`$lonStr.Replace(',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
                                    `$now = [datetime]::Now
                                    `$times = [DarkSwitch.SunCalc]::GetSunTimes(`$latD, `$lonD, `$now)
                                    
                                    if (`$times[0] -ne [datetime]::MinValue) {
                                        try {
                                            `$tL = Get-ScheduledTask -TaskName "DarkSwitch - Light Mode" -TaskPath `$tPath -ErrorAction Stop
                                            `$tL.Triggers[0].StartBoundary = `$times[0].ToString("yyyy-MM-ddTHH:mm:ss")
                                            `$tL | Set-ScheduledTask -User `$env:USERNAME -ErrorAction Stop | Out-Null
                                        } catch {}
                                        
                                        try {
                                            `$tD = Get-ScheduledTask -TaskName "DarkSwitch - Dark Mode" -TaskPath `$tPath -ErrorAction Stop
                                            `$tD.Triggers[0].StartBoundary = `$times[1].ToString("yyyy-MM-ddTHH:mm:ss")
                                            `$tD | Set-ScheduledTask -User `$env:USERNAME -ErrorAction Stop | Out-Null
                                        } catch {}
                                        
                                        `$shouldBeLight = (`$now.TimeOfDay -ge `$times[0].TimeOfDay -and `$now.TimeOfDay -lt `$times[1].TimeOfDay)
                                        `$expectedVal = if (`$shouldBeLight) { 1 } else { 0 }
                                        
                                        `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                                        if (`$currApp -ne `$expectedVal) {
                                            [DarkSwitch.Engine]::RefreshCurrent()
                                        }
                                        Add-Log "Sun times forced & instantly applied successfully!"
                                    } else { Add-Log "Calculation returned invalid times." }
                                } else { Add-Log "Location missing. Please re-enable Dynamic Mode." }
                            } catch { Add-Log "Error during calculation: `$(`$_.Exception.Message)" }
                        }
                        
                        `$global:menuState = "Menu_Mode"
                        `$global:selIndex = 0
                        `$needsRefresh = `$true
                    }
                    "Force_SunUpdate" {
                        Show-Loading "Forcing Sun Update"
                        Set-ItemProperty "HKCU:\SOFTWARE\DarkSwitch" -Name "OverrideTime" -Value 0 -Type QWord -Force -ErrorAction SilentlyContinue
                        Start-Process -FilePath "wscript.exe" -ArgumentList ('"{0}" "{1}\CoreEngine.ps1" SUN' -f `$vbs, `$engineDir) -WindowStyle Hidden -ErrorAction SilentlyContinue
                        Add-Log "Sun times forced & instantly applied successfully!"
                        `$global:menuState = "Menu_Mode"
                        `$global:selIndex = 0
                        `$needsRefresh = `$true
                    }
                    "Toggle_WP" {
                        Show-Loading "Updating Wallpaper settings"
                        `$newEn = if (`$wpEn -eq 1) { 0 } else { 1 }
                        if (`$newEn -eq 1) {
                            `$bgType = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers' -Name BackgroundType -ErrorAction SilentlyContinue).BackgroundType
                            if (`$null -eq `$bgType) { `$bgType = 0 }
                            
                            Set-ConfigValue "BackupWpMode" `$bgType "DWord"
                            Set-ConfigValue "LightWpMode" `$bgType "DWord"
                            Set-ConfigValue "DarkWpMode" `$bgType "DWord"

                            `$curWp = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallPaper -ErrorAction SilentlyContinue).WallPaper
                            if (`$curWp -and (Test-Path `$curWp)) {
                                `$ext = [System.IO.Path]::GetExtension(`$curWp)
                                if (-not (Test-Path `$wpDir)) { New-Item -ItemType Directory -Path `$wpDir -Force | Out-Null }
                                `$backupWp = "`$wpDir\Default_WP`$ext"
                                if (`$curWp -ne `$backupWp) { Copy-Item `$curWp `$backupWp -Force }
                                Set-ConfigValue "BackupWpFile" `$backupWp
                                Set-ConfigValue "LightWpFile" `$backupWp
                                Set-ConfigValue "DarkWpFile" `$backupWp
                            }
                            
                            `$curCol = (Get-ItemProperty 'HKCU:\Control Panel\Colors' -Name Background -ErrorAction SilentlyContinue).Background
                            if (`$curCol) {
                                try {
                                    `$parts = `$curCol -split ' '
                                    `$hexCol = "#{0:X2}{1:X2}{2:X2}" -f [int]`$parts[0], [int]`$parts[1], [int]`$parts[2]
                                } catch { `$hexCol = "#000000" }
                            } else { `$hexCol = "#000000" }
                            Set-ConfigValue "BackupWpColor" `$hexCol
                            Set-ConfigValue "LightWpColor" `$hexCol
                            Set-ConfigValue "DarkWpColor" `$hexCol
                            
                            `$curFold = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers' -Name SlideshowDirectoryPath1 -ErrorAction SilentlyContinue).SlideshowDirectoryPath1
                            if (-not `$curFold) { `$curFold = "" }
                            `$curTick = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers' -Name SlideshowTick -ErrorAction SilentlyContinue).SlideshowTick
                            if (-not `$curTick) { `$curTick = 600000 }
                            
                            Set-ConfigValue "BackupWpFolder" `$curFold
                            Set-ConfigValue "LightWpFolder" `$curFold
                            Set-ConfigValue "DarkWpFolder" `$curFold
                            Set-ConfigValue "BackupWpInterval" `$curTick "DWord"
                            Set-ConfigValue "LightWpInterval" `$curTick "DWord"
                            Set-ConfigValue "DarkWpInterval" `$curTick "DWord"
                            
                            Add-Log "WP Switch ON: Backed up current WP states as Default."
                        } else {
                            `$bMode = `$regData.BackupWpMode
                            if (`$null -ne `$bMode) {
                                `$bFile = `$regData.BackupWpFile
                                `$bColor = `$regData.BackupWpColor
                                `$bFolder = `$regData.BackupWpFolder
                                `$bTick = `$regData.BackupWpInterval
                                try {
                                    [DarkSwitch.Engine]::ApplyWpMode([int]`$bMode, "`$bFile", "`$bColor", "`$bFolder", [int]`$bTick)
                                    Add-Log "WP Switch OFF: Restored original Wallpaper settings."
                                } catch { Add-Log "WP Switch OFF: Failed to restore backup settings." }
                            } else {
                                `$bWp = (Get-ChildItem "`$wpDir\Default_WP.*" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
                                if (`$bWp -and (Test-Path `$bWp)) { [DarkSwitch.Engine]::ApplyWpMode(0, `$bWp, "", "", 60000) }
                                Add-Log "WP Switch OFF: Restored Default picture."
                            }
                        }
                        Set-ConfigValue "WallpaperEnabled" `$newEn "DWord"
                        [DarkSwitch.Engine]::RefreshCurrent()
                        `$needsRefresh = `$true
                    }
                    "Set_WpFile_L" {
                        `$wpInput = Show-InputScreen -Title "Light Wallpaper Image" -PromptStr "Enter Absolute Path to Image" -CurrentValue `$lWallName -DefaultValue "Default" -Format "Absolute Path (e.g. C:\images\light.jpg)" -Description "Set the picture applied during Light mode."
                        if (`$wpInput -eq 'ESC_CANCEL') { Add-Log "Cancelled."; `$global:menuState = "Menu_Wallpaper_Light"; `$global:selIndex = 0; `$needsRefresh = `$true; break }
                        Show-Loading "Updating light wallpaper"
                        if (`$wpInput -eq 'none') {
                            Remove-ConfigValue "LightWpFile"
                            Remove-ConfigValue "LightWallpaperName"
                            Remove-Item "`$wpDir\Light_*" -Force -ErrorAction SilentlyContinue
                            Add-Log "Light wallpaper removed"
                            `$global:menuState = "Menu_Wallpaper_Light"
                        } elseif (Test-Path `$wpInput) {
                            if (-not (Test-Path `$wpDir)) { New-Item -ItemType Directory -Path `$wpDir -Force | Out-Null }
                            `$ext = [System.IO.Path]::GetExtension(`$wpInput)
                            `$dest = Join-Path `$wpDir "Light_WP`$ext"
                            `$wpFileName = [System.IO.Path]::GetFileName(`$wpInput)
                            Remove-Item "`$wpDir\Light_*" -Force -ErrorAction SilentlyContinue
                            Copy-Item `$wpInput `$dest -Force
                            Set-ConfigValue "LightWpFile" `$dest
                            Set-ConfigValue "LightWallpaperName" `$wpFileName
                            
                            `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                            if (`$currApp -eq 1 -and `$regData.LightWpMode -eq 0) { [DarkSwitch.Engine]::RefreshCurrent() }
                            Add-Log "Light wallpaper picture successfully set to `$wpFileName"
                            `$global:menuState = "Menu_Wallpaper_Light"
                        } else { Add-Log "Invalid path." }
                        `$global:selIndex = 0
                        `$needsRefresh = `$true
                    }
                    "Set_WpColor_L" {
                        `$colInput = Show-InputScreen -Title "Light Solid Color" -PromptStr "Enter HEX Color" -CurrentValue `$regData.LightWpColor -DefaultValue "#000000" -Format "HEX (e.g. #1E1E1E)" -Description "Set the custom solid color applied during Light mode."
                        if (`$colInput -eq 'ESC_CANCEL') { Add-Log "Cancelled."; `$global:menuState = "Menu_WpColorType_L"; `$global:selIndex = 0; `$needsRefresh = `$true; break }
                        if (`$colInput -match '^#?([a-fA-F0-9]{6})$') {
                            Show-Loading "Updating Light Color"
                            Set-ConfigValue "LightWpColor" ("#" + `$matches[1].ToUpper())
                            `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                            if (`$currApp -eq 1 -and `$regData.LightWpMode -eq 1) { [DarkSwitch.Engine]::RefreshCurrent() }
                            Add-Log "Light Solid Color updated to `$colInput"
                            `$global:menuState = "Menu_Wallpaper_Light"
                        } else { Add-Log "Invalid HEX Color." }
                        `$global:selIndex = 0
                        `$needsRefresh = `$true
                    }
                    "Set_WpFolder_L" {
                        `$currFld = if ([string]::IsNullOrWhiteSpace(`$regData.LightWpFolder)) { "" } else { `$regData.LightWpFolder }
                        `$fldInput = Show-InputScreen -Title "Light Slideshow Folder" -PromptStr "Enter Absolute Path to Folder (or 'none')" -CurrentValue (if(`$currFld){`$currFld}else{"Not set"}) -DefaultValue "none" -Format "Absolute Path (e.g. C:\Wallpapers)" -Description "Set the folder containing slideshow images for Light mode." -HelpText @(" `$cYellow[!] If not set, the fallback picture wallpaper will be used.`$cReset")
                        
                        if (`$fldInput -eq 'ESC_CANCEL') { Add-Log "Cancelled."; `$global:menuState = "Menu_Wallpaper_Light"; `$global:selIndex = 0; `$needsRefresh = `$true; break }
                        
                        if ([string]::IsNullOrWhiteSpace(`$fldInput) -or `$fldInput.ToLower() -eq 'none') {
                            Show-Loading "Clearing Light Folder"
                            Set-ConfigValue "LightWpFolder" ""
                            `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                            if (`$currApp -eq 1 -and `$regData.LightWpMode -eq 2) { [DarkSwitch.Engine]::RefreshCurrent() }
                            Add-Log "Light Slideshow Folder cleared"
                            `$global:menuState = "Menu_Wallpaper_Light"
                        } elseif (Test-Path `$fldInput -PathType Container) {
                            Show-Loading "Updating Light Folder"
                            Set-ConfigValue "LightWpFolder" `$fldInput
                            `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                            if (`$currApp -eq 1 -and `$regData.LightWpMode -eq 2) { [DarkSwitch.Engine]::RefreshCurrent() }
                            Add-Log "Light Slideshow Folder updated"
                            `$global:menuState = "Menu_Wallpaper_Light"
                        } else { Add-Log "Invalid Folder Path." }
                        `$global:selIndex = 0
                        `$needsRefresh = `$true
                    }
                    "Set_WpFile_D" {
                        `$wpInput = Show-InputScreen -Title "Dark Wallpaper Image" -PromptStr "Enter Absolute Path to Image" -CurrentValue `$dWallName -DefaultValue "Default" -Format "Absolute Path (e.g. C:\images\dark.jpg)" -Description "Set the picture applied during Dark mode."
                        if (`$wpInput -eq 'ESC_CANCEL') { Add-Log "Cancelled."; `$global:menuState = "Menu_Wallpaper_Dark"; `$global:selIndex = 0; `$needsRefresh = `$true; break }
                        Show-Loading "Updating dark wallpaper"
                        if (`$wpInput -eq 'none') {
                            Remove-ConfigValue "DarkWpFile"
                            Remove-ConfigValue "DarkWallpaperName"
                            Remove-Item "`$wpDir\Dark_*" -Force -ErrorAction SilentlyContinue
                            Add-Log "Dark wallpaper removed"
                            `$global:menuState = "Menu_Wallpaper_Dark"
                        } elseif (Test-Path `$wpInput) {
                            if (-not (Test-Path `$wpDir)) { New-Item -ItemType Directory -Path `$wpDir -Force | Out-Null }
                            `$ext = [System.IO.Path]::GetExtension(`$wpInput)
                            `$dest = Join-Path `$wpDir "Dark_WP`$ext"
                            `$wpFileName = [System.IO.Path]::GetFileName(`$wpInput)
                            Remove-Item "`$wpDir\Dark_*" -Force -ErrorAction SilentlyContinue
                            Copy-Item `$wpInput `$dest -Force
                            Set-ConfigValue "DarkWpFile" `$dest
                            Set-ConfigValue "DarkWallpaperName" `$wpFileName
                            
                            `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                            if (`$currApp -eq 0 -and `$regData.DarkWpMode -eq 0) { [DarkSwitch.Engine]::RefreshCurrent() }
                            Add-Log "Dark wallpaper picture successfully set to `$wpFileName"
                            `$global:menuState = "Menu_Wallpaper_Dark"
                        } else { Add-Log "Invalid path." }
                        `$global:selIndex = 0
                        `$needsRefresh = `$true
                    }
                    "Set_WpColor_D" {
                        `$colInput = Show-InputScreen -Title "Dark Custom Solid Color" -PromptStr "Enter HEX Color" -CurrentValue `$regData.DarkWpColor -DefaultValue "#000000" -Format "HEX (e.g. #1E1E1E)" -Description "Set the custom solid color applied during Dark mode."
                        if (`$colInput -eq 'ESC_CANCEL') { Add-Log "Cancelled."; `$global:menuState = "Menu_WpColorType_D"; `$global:selIndex = 0; `$needsRefresh = `$true; break }
                        if (`$colInput -match '^#?([a-fA-F0-9]{6})$') {
                            Show-Loading "Updating Dark Color"
                            Set-ConfigValue "DarkWpColor" ("#" + `$matches[1].ToUpper())
                            `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                            if (`$currApp -eq 0 -and `$regData.DarkWpMode -eq 1) { [DarkSwitch.Engine]::RefreshCurrent() }
                            Add-Log "Dark Solid Color updated to `$colInput"
                            `$global:menuState = "Menu_Wallpaper_Dark"
                        } else { Add-Log "Invalid HEX Color." }
                        `$global:selIndex = 0
                        `$needsRefresh = `$true
                    }
                    "Set_WpFolder_D" {
                        `$currFld = if ([string]::IsNullOrWhiteSpace(`$regData.DarkWpFolder)) { "" } else { `$regData.DarkWpFolder }
                        `$fldInput = Show-InputScreen -Title "Dark Slideshow Folder" -PromptStr "Enter Absolute Path to Folder (or 'none')" -CurrentValue (if(`$currFld){`$currFld}else{"Not set"}) -DefaultValue "none" -Format "Absolute Path (e.g. C:\Wallpapers)" -Description "Set the folder containing slideshow images for Dark mode." -HelpText @(" `$cYellow[!] If not set, the fallback picture wallpaper will be used.`$cReset")
                        
                        if (`$fldInput -eq 'ESC_CANCEL') { Add-Log "Cancelled."; `$global:menuState = "Menu_Wallpaper_Dark"; `$global:selIndex = 0; `$needsRefresh = `$true; break }
                        
                        if ([string]::IsNullOrWhiteSpace(`$fldInput) -or `$fldInput.ToLower() -eq 'none') {
                            Show-Loading "Clearing Dark Folder"
                            Set-ConfigValue "DarkWpFolder" ""
                            `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                            if (`$currApp -eq 0 -and `$regData.DarkWpMode -eq 2) { [DarkSwitch.Engine]::RefreshCurrent() }
                            Add-Log "Dark Slideshow Folder cleared"
                            `$global:menuState = "Menu_Wallpaper_Dark"
                        } elseif (Test-Path `$fldInput -PathType Container) {
                            Show-Loading "Updating Dark Folder"
                            Set-ConfigValue "DarkWpFolder" `$fldInput
                            `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                            if (`$currApp -eq 0 -and `$regData.DarkWpMode -eq 2) { [DarkSwitch.Engine]::RefreshCurrent() }
                            Add-Log "Dark Slideshow Folder updated"
                            `$global:menuState = "Menu_Wallpaper_Dark"
                        } else { Add-Log "Invalid Folder Path." }
                        `$global:selIndex = 0
                        `$needsRefresh = `$true
                    }
                    "Toggle_Acc" {
                        Show-Loading "Updating Accent settings"
                        `$newAccEn = if (`$accEn -eq 1) { 0 } else { 1 }
                        if (`$newAccEn -eq 1) {
                            `$curAuto = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name AutoColorization -ErrorAction SilentlyContinue).AutoColorization
                            `$curAcc = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\DWM' -Name AccentColor -ErrorAction SilentlyContinue).AccentColor
                            if (`$null -ne `$curAuto -and `$null -ne `$curAcc) {
                                Set-ConfigValue "BackupAutoCol" `$curAuto "DWord"
                                Set-ConfigValue "BackupAccCol" `$curAcc "DWord"
                                if (`$curAuto -ne 1 -and `$curAcc -ne `$null) {
                                    `$r = (`$curAcc -band 0xFF).ToString("X2"); `$g = ((`$curAcc -shr 8) -band 0xFF).ToString("X2"); `$b = ((`$curAcc -shr 16) -band 0xFF).ToString("X2")
                                    `$accStr = "#`$r`$g`$b"
                                    Set-ConfigValue "LightAccMode" 2 "DWord"
                                    Set-ConfigValue "DarkAccMode" 2 "DWord"
                                    Set-ConfigValue "LightAccCustom" `$accStr
                                    Set-ConfigValue "DarkAccCustom" `$accStr
                                    Set-ConfigValue "LightAccent" `$accStr
                                    Set-ConfigValue "DarkAccent" `$accStr
                                } else {
                                    Set-ConfigValue "LightAccMode" 0 "DWord"
                                    Set-ConfigValue "DarkAccMode" 0 "DWord"
                                    Set-ConfigValue "LightAccent" "auto"
                                    Set-ConfigValue "DarkAccent" "auto"
                                }
                                Add-Log "Accent Switch ON: Backed up current Accent to be used as default."
                            } else { Add-Log "Accent Switch ON" }
                        } else {
                            `$bAuto = (Get-ItemProperty 'HKCU:\SOFTWARE\DarkSwitch' -Name BackupAutoCol -ErrorAction SilentlyContinue).BackupAutoCol
                            `$bAcc = (Get-ItemProperty 'HKCU:\SOFTWARE\DarkSwitch' -Name BackupAccCol -ErrorAction SilentlyContinue).BackupAccCol
                            if (`$null -ne `$bAuto -and `$null -ne `$bAcc) {
                                try {
                                    [DarkSwitch.Engine]::RestoreAccent([int]`$bAuto, [long]`$bAcc)
                                    Add-Log "Accent Switch OFF: Restored original Accent Color."
                                } catch {
                                    [DarkSwitch.Engine]::ApplyAcc("auto")
                                    Add-Log "Accent Switch OFF: Failed to restore exact color, reverted to Auto."
                                }
                            } else {
                                [DarkSwitch.Engine]::ApplyAcc("auto")
                                Add-Log "Accent Switch OFF: Restored Accent to Auto."
                            }
                        }
                        Set-ConfigValue "AccentEnabled" `$newAccEn "DWord"
                        [DarkSwitch.Engine]::RefreshCurrent()
                        `$needsRefresh = `$true
                    }
                    "Set_Acc_Custom_L" {
                        while (`$true) {
                            `$accInput = Show-InputScreen -Title "Custom Light Accent" -PromptStr "Enter HEX Color" -CurrentValue `$lAccCust -DefaultValue "#0078D4" -Format "HEX (e.g. #FF5500)" -Description "Set the custom accent color applied during Light mode."
                            if (`$accInput -eq 'ESC_CANCEL') { Add-Log "Cancelled."; `$global:menuState = "Menu_Accent_Light"; `$global:selIndex = 0; `$needsRefresh = `$true; break }
                            
                            if (`$accInput -match '^#?([a-fA-F0-9]{6})$') {
                                `$hex = `$matches[1]
                                `$r = [Convert]::ToInt32(`$hex.Substring(0, 2), 16)
                                `$g = [Convert]::ToInt32(`$hex.Substring(2, 2), 16)
                                `$b = [Convert]::ToInt32(`$hex.Substring(4, 2), 16)
                                
                                `$pb = [Math]::Sqrt(0.299*`$r*`$r + 0.587*`$g*`$g + 0.114*`$b*`$b)
                                
                                if (`$pb -gt 235 -or `$pb -lt 20) {
                                    Write-Host "`n   `$cRed[!] Color not supported. Please pick a different color.`$cReset" 
                                    Start-Sleep -Seconds 2
                                    continue
                                }
                                
                                if (`$pb -gt 210 -or `$pb -lt 40) {
                                    Write-Host "`n   `$cYellow[!] Color might be hard to read. Press Y to proceed, or N to try again.`$cReset " -NoNewline
                                    `$k = [Console]::ReadKey(`$true)
                                    if (`$k.KeyChar -notmatch '^[Yy]$') { continue }
                                }
                                
                                Show-Loading "Updating custom accent"
                                `$finalHex = "#" + `$hex.ToUpper()
                                Set-ConfigValue "LightAccCustom" `$finalHex "String"
                                if (`$lAccMode -eq 2) {
                                    Set-ConfigValue "LightAccent" `$finalHex "String"
                                    `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                                    if (`$currApp -eq 1) { [DarkSwitch.Engine]::RefreshCurrent() }
                                }
                                Add-Log "Light Custom Accent updated"
                                break
                            } else {
                                Write-Host "`n   `$cRed-> Invalid input. Must be a valid HEX code.`$cReset"
                                Start-Sleep -Seconds 1
                            }
                        }
                        `$global:menuState = "Menu_Accent_Light"
                        `$global:selIndex = 0
                        `$needsRefresh = `$true
                    }
                    "Set_Acc_Custom_D" {
                        while (`$true) {
                            `$accInput = Show-InputScreen -Title "Custom Dark Accent" -PromptStr "Enter HEX Color" -CurrentValue `$dAccCust -DefaultValue "#0078D4" -Format "HEX (e.g. #0055FF)" -Description "Set the custom accent color applied during Dark mode."
                            if (`$accInput -eq 'ESC_CANCEL') { Add-Log "Cancelled."; `$global:menuState = "Menu_Accent_Dark"; `$global:selIndex = 0; `$needsRefresh = `$true; break }
                            
                            if (`$accInput -match '^#?([a-fA-F0-9]{6})$') {
                                `$hex = `$matches[1]
                                `$r = [Convert]::ToInt32(`$hex.Substring(0, 2), 16)
                                `$g = [Convert]::ToInt32(`$hex.Substring(2, 2), 16)
                                `$b = [Convert]::ToInt32(`$hex.Substring(4, 2), 16)
                                
                                `$pb = [Math]::Sqrt(0.299*`$r*`$r + 0.587*`$g*`$g + 0.114*`$b*`$b)
                                
                                if (`$pb -gt 235 -or `$pb -lt 20) {
                                    Write-Host "`n   `$cRed[!] Color not supported. Please pick a different color.`$cReset" 
                                    Start-Sleep -Seconds 2
                                    continue
                                }
                                
                                if (`$pb -gt 210 -or `$pb -lt 40) {
                                    Write-Host "`n   `$cYellow[!] Color might be hard to read. Press Y to proceed, or N to try again.`$cReset " -NoNewline
                                    `$k = [Console]::ReadKey(`$true)
                                    if (`$k.KeyChar -notmatch '^[Yy]$') { continue }
                                }
                                
                                Show-Loading "Updating custom accent"
                                `$finalHex = "#" + `$hex.ToUpper()
                                Set-ConfigValue "DarkAccCustom" `$finalHex "String"
                                if (`$dAccMode -eq 2) {
                                    Set-ConfigValue "DarkAccent" `$finalHex "String"
                                    `$currApp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                                    if (`$currApp -eq 0) { [DarkSwitch.Engine]::RefreshCurrent() }
                                }
                                Add-Log "Dark Custom Accent updated"
                                break
                            } else {
                                Write-Host "`n   `$cRed-> Invalid input. Must be a valid HEX code.`$cReset"
                                Start-Sleep -Seconds 1
                            }
                        }
                        `$global:menuState = "Menu_Accent_Dark"
                        `$global:selIndex = 0
                        `$needsRefresh = `$true
                    }
                    "Toggle_Cursor" {
                        Show-Loading "Updating Cursor settings"
                        `$newCurEn = if (`$curEn -eq 1) { 0 } else { 1 }
                        if (`$newCurEn -eq 0) { [DarkSwitch.Engine]::ApplyCursor("Windows Default") }
                        Set-ConfigValue "CursorEnabled" `$newCurEn "DWord"
                        [DarkSwitch.Engine]::RefreshCurrent()
                        `$needsRefresh = `$true
                    }
                    "Toggle_Boot" {
                        Show-Loading "Updating boot settings"
                        if (`$tBootState -ne 'Disabled') { 
                            try { Disable-ScheduledTask -TaskName "DarkSwitch - Boot Sync" -TaskPath `$tPath -ErrorAction Stop | Out-Null } catch {}
                            Add-Log "Boot trigger disabled"
                            Set-ConfigValue "BootSync" "N"
                        } else { 
                            try { Enable-ScheduledTask -TaskName "DarkSwitch - Boot Sync" -TaskPath `$tPath -ErrorAction Stop | Out-Null } catch {}
                            Add-Log "Boot trigger enabled"
                            Set-ConfigValue "BootSync" "Y"
                        }
                        `$needsRefresh = `$true
                    }
                    "Toggle_Sm" {
                        Show-Loading "Updating Start Menu"
                        if (Test-Path `$smPath) {
                            `$item = Get-Item `$smPath -Force
                            if (`$isSmHidden) { 
                                `$item.Attributes = `$item.Attributes -band (-bnot [System.IO.FileAttributes]::Hidden)
                                Add-Log "Start menu items set to Visible"
                            } else { 
                                `$item.Attributes = `$item.Attributes -bor [System.IO.FileAttributes]::Hidden
                                Add-Log "Start menu items set to Hidden"
                            }
                            Start-Sleep -Seconds 2
                            [Shell.WinAPI]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
                        }
                        `$needsRefresh = `$true
                    }
                    "Toggle_Hk" {
                        Show-Loading "Updating shortcut"
                        if (`$hkEnabled) { 
                            `$scToggle.Hotkey = ""; `$scToggle.Save() 
                            Add-Log "Keyboard shortcut disabled"
                            Set-ConfigValue "Shortcut" "N"
                        } else { 
                            `$scToggle.Hotkey = ""; `$scToggle.Save()
                            Start-Sleep -Milliseconds 200
                            `$scToggle.Hotkey = "Ctrl+Alt+" + `$savedKey; `$scToggle.Save() 
                            Add-Log "Keyboard shortcut enabled (Ctrl+Alt+`$savedKey)"
                            Set-ConfigValue "Shortcut" "Y"
                        }
                        `$needsRefresh = `$true
                    }
                    "Change_Hk" {
                        while (`$true) {
                            `$newK = Show-InputScreen -Title "Shortcut Key" -PromptStr "Enter new key to use with Ctrl+Alt" -CurrentValue `$savedKey -DefaultValue "T" -Format "Single Key (A-Z, 0-9)" -Description "Bind a new key letter to toggle your theme on the fly."
                            if (`$newK -eq 'ESC_CANCEL') { Add-Log "Cancelled."; break }
                            if (`$newK -match '^[a-zA-Z0-9]$') { 
                                Show-Loading "Updating shortcut"
                                `$nk = `$newK.ToUpper()
                                `$hotkey = "Ctrl+Alt+" + `$nk
                                `$scToggle.Hotkey = ""; `$scToggle.Save()
                                Start-Sleep -Milliseconds 200
                                `$scToggle.Hotkey = `$hotkey; `$scToggle.Save()
                                Set-ConfigValue "ShortcutKey" `$nk
                                Add-Log "Shortcut key updated to `$hotkey"
                                break 
                            }
                            Write-Host "`n   `$cRed-> Invalid key. Use a single letter or number.`$cReset" 
                            Start-Sleep -Seconds 1
                        }
                        `$needsRefresh = `$true
                    }
                    "Toggle_Logging" {
                        Show-Loading "Updating core settings"
                        `$newLogEn = if (`$global:logEn -eq 1) { 0 } else { 1 }
                        Set-ConfigValue "LoggingEnabled" `$newLogEn "DWord"
                        `$global:logEn = `$newLogEn
                        if (`$newLogEn -eq 0) {
                            `$global:sectionLogs = @()
                            try { Remove-Item `$global:logFile -Force -ErrorAction SilentlyContinue } catch {}
                            `$global:lastMsg = "Session logging disabled and file deleted."
                        } else {
                            Add-Log "Session logging enabled."
                        }
                        `$needsRefresh = `$true
                    }
                    "Toggle_TopNav" {
                        Show-Loading "Updating navigation settings"
                        `$newTopNav = if (`$global:topNavEn -eq 1) { 0 } else { 1 }
                        Set-ConfigValue "TopNavEnabled" `$newTopNav "DWord"
                        `$global:topNavEn = `$newTopNav
                        if (`$newTopNav -eq 0) {
                            Add-Log "Top navigation bar disabled."
                        } else {
                            Add-Log "Top navigation bar enabled."
                        }
                        `$needsRefresh = `$true
                    }
                    "Toggle_UpdateMenu" {
                        Show-Loading "Updating menu settings"
                        `$newUpdEn = if (`$global:updMenuEn -eq 1) { 0 } else { 1 }
                        Set-ConfigValue "UpdateMenuEnabled" `$newUpdEn "DWord"
                        `$global:updMenuEn = `$newUpdEn
                        if (`$newUpdEn -eq 0) {
                            Add-Log "Update menu disabled."
                        } else {
                            Add-Log "Update menu enabled."
                        }
                        `$needsRefresh = `$true
                    }
                    "Do_Toggle" {
                        Show-Loading "Toggling Theme"
                        [DarkSwitch.Engine]::Toggle()
                        Add-Log "Theme toggled instantly."
                        `$needsRefresh = `$true
                    }
                    "Reset_DarkSwitch" {
                        `$ans = Show-InputScreen -Title "Reset Dark Switch" -PromptStr "Are you sure?" -CurrentValue "" -DefaultValue "N" -Format "Y/N" -Description "Restore all Dark Switch settings to default and recreate tasks." -HelpText @(" `$cRed[!] This will reset all Dark Switch settings and recreate tasks.`$cReset")
                        if (`$ans -eq 'ESC_CANCEL') { Add-Log "Cancelled."; `$needsRefresh = `$true; break }
                        if (`$ans -match '^[Yy]') {
                            Show-Loading "Resetting Dark Switch"
                            
                            # Clean Registry and Config file
                            if (Test-Path "HKCU:\SOFTWARE\DarkSwitch") { Remove-Item "HKCU:\SOFTWARE\DarkSwitch" -Recurse -Force -ErrorAction SilentlyContinue }
                            New-Item -Path "HKCU:\SOFTWARE\DarkSwitch" -Force | Out-Null
                            
                            `$cfgPath = "C:\Program Files\Detaroxz\DarkSwitch\config.ini"
                            if (Test-Path `$cfgPath) { Remove-Item `$cfgPath -Force -ErrorAction SilentlyContinue }
                            
                            # Setup Default config keys
                            Set-ConfigValue "LightTime" `$defLight
                            Set-ConfigValue "DarkTime" `$defDark
                            Set-ConfigValue "BootSync" "Y"
                            Set-ConfigValue "Shortcut" "Y"
                            Set-ConfigValue "ShortcutKey" "T"
                            Set-ConfigValue "WallpaperEnabled" 0 "DWord"
                            Set-ConfigValue "AccentEnabled" 0 "DWord"
                            Set-ConfigValue "CursorEnabled" 0 "DWord"
                            Set-ConfigValue "DynamicSun" "N"
                            Set-ConfigValue "SunSyncBoot" "Y"
                            Set-ConfigValue "LoggingEnabled" 0 "DWord"
                            Set-ConfigValue "TopNavEnabled" 1 "DWord"
                            Set-ConfigValue "UpdateMenuEnabled" 1 "DWord"
                            
                            # Recreate Task Actions and Details
                            `$tPath = "\Detaroxz\DarkSwitch\"
                            `$engDir = "C:\Program Files\Detaroxz\DarkSwitch\Engine"
                            `$vbsRunner = "`$engDir\RunSilent.vbs"
                            
                            try { Get-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath `$tPath -ErrorAction Stop | Unregister-ScheduledTask -Confirm:`$false -ErrorAction Stop } catch {}
                            
                            function Get-TaskAction (`$Type) {
                                if (`$Type -eq 'TOGGLE') {
                                    return New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"`$engDir\Toggle.vbs`""
                                } else {
                                    return New-ScheduledTaskAction -Execute "wscript.exe" -Argument ('"{0}" "{1}\CoreEngine.ps1" {2}' -f `$vbsRunner, `$engDir, `$Type)
                                }
                            }
                            
                            `$actSyncLight = Get-TaskAction "SYNC_LIGHT"
                            `$actSyncDark  = Get-TaskAction "SYNC_DARK"
                            `$actBoot = Get-TaskAction "BOOT"
                            
                            # Light Mode Trigger
                            try { `$ptL = Get-Date `$defLight } catch { `$ptL = (Get-Date).Date.AddHours(7) }
                            `$trigL = New-ScheduledTaskTrigger -Daily -At `$ptL
                            try { Register-ScheduledTask -TaskName "DarkSwitch - Light Mode" -TaskPath `$tPath -Action `$actSyncLight -Principal `$p -Trigger `$trigL -Settings `$settings -Force -ErrorAction Stop | Out-Null } catch {}
                            
                            # Dark Mode Trigger
                            try { `$ptD = Get-Date `$defDark } catch { `$ptD = (Get-Date).Date.AddHours(19) }
                            `$trigD = New-ScheduledTaskTrigger -Daily -At `$ptD
                            try { Register-ScheduledTask -TaskName "DarkSwitch - Dark Mode" -TaskPath `$tPath -Action `$actSyncDark -Principal `$p -Trigger `$trigD -Settings `$settings -Force -ErrorAction Stop | Out-Null } catch {}
                            
                            # Boot Sync Trigger
                            `$taskB = New-ScheduledTask -Action `$actBoot -Principal `$p -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Settings `$settings
                            try { Register-ScheduledTask -TaskName "DarkSwitch - Boot Sync" -TaskPath `$tPath -InputObject `$taskB -Force -ErrorAction Stop | Out-Null } catch {}
                            
                            # Toggle Task
                            `$actTog = Get-TaskAction "TOGGLE"
                            `$taskT = New-ScheduledTask -Action `$actTog -Principal `$p -Settings `$settings
                            try { Register-ScheduledTask -TaskName "DarkSwitch - Quick Toggle" -TaskPath `$tPath -InputObject `$taskT -Force -ErrorAction Stop | Out-Null } catch {}
                            
                            foreach (`$t in @("DarkSwitch - Light Mode", "DarkSwitch - Dark Mode", "DarkSwitch - Boot Sync")) {
                                `$xml = try { Export-ScheduledTask -TaskName `$t -TaskPath `$tPath -ErrorAction Stop | Out-String } catch { `$null }
                                if (`$xml) {
                                    if (`$t -eq "DarkSwitch - Boot Sync") { `$xml = `$xml -replace '</Triggers>', '<SessionStateChangeTrigger><StateChange>SessionUnlock</StateChange></SessionStateChangeTrigger></Triggers>' }
                                    if (`$xml -match '<Priority>\s*\d+\s*</Priority>') { `$xml = `$xml -replace '<Priority>\s*\d+\s*</Priority>', '<Priority>2</Priority>' }
                                    else { `$xml = `$xml -replace '</Settings>', "  <Priority>2</Priority>`n  </Settings>" }
                                    try { Register-ScheduledTask -TaskName `$t -TaskPath `$tPath -Xml `$xml -Force -User `$env:USERNAME -ErrorAction Stop | Out-Null } catch {}
                                }
                            }

                            `$xmlTog = try { Export-ScheduledTask -TaskName "DarkSwitch - Quick Toggle" -TaskPath `$tPath -ErrorAction Stop | Out-String } catch { `$null }
                            if (`$xmlTog) {
                                if (`$xmlTog -match '<Priority>\s*\d+\s*</Priority>') { `$xmlTog = `$xmlTog -replace '<Priority>\s*\d+\s*</Priority>', '<Priority>0</Priority>' }
                                else { `$xmlTog = `$xmlTog -replace '</Settings>', "  <Priority>0</Priority>`n  </Settings>" }
                                try { Register-ScheduledTask -TaskName "DarkSwitch - Quick Toggle" -TaskPath `$tPath -Xml `$xmlTog -Force -User `$env:USERNAME -ErrorAction Stop | Out-Null } catch {}
                            }

                            # Restoring Keyboard Shortcut
                            `$scToggle.Hotkey = ""; `$scToggle.Save()
                            Start-Sleep -Milliseconds 200
                            `$scToggle.Hotkey = "Ctrl+Alt+T"; `$scToggle.Save()
                            
                            Add-Log "Dark Switch successfully reset to defaults."
                        } else {
                            Add-Log "Reset cancelled."
                        }
                        `$needsRefresh = `$true
                    }
                    "Uninstall_DarkSwitch" {
                        `$ans = Show-InputScreen -Title "Uninstall Dark Switch" -PromptStr "Are you sure?" -CurrentValue "" -DefaultValue "N" -Format "Y/N" -Description "Completely remove Dark Switch from your system." -HelpText @(" `$cRed[!] This will completely remove Dark Switch from your system.`$cReset")
                        if (`$ans -eq 'ESC_CANCEL') { Add-Log "Cancelled."; `$needsRefresh = `$true; break }
                        if (`$ans -match '^[Yy]') {
                            `$uninst = "C:\Program Files\Detaroxz\DarkSwitch\Uninstall.ps1"
                            if (Test-Path `$uninst) {
                                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"`$uninst`""
                                exit
                            } else {
                                Add-Log "Uninstaller not found!"
                            }
                        } else {
                            Add-Log "Uninstall cancelled."
                        }
                        `$needsRefresh = `$true
                    }
                    "Update_Check" {
                        Hide-Loading
                        Write-Host "`n   `$cDim> Checking GitHub for updates...`$cReset"
                        try {
                            `$remoteVer = (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/avm3005/detaroxzDarkSwitch/main/UpdSystem/version.txt" -UseBasicParsing).Trim() -replace '^v', ''
                            if ([version]`$remoteVer -gt [version]"`$appVersion") {
                                `$ans = Show-InputScreen -Title "Update Available" -PromptStr "Do you want to download and apply this update now?" -CurrentValue "v$appVersion" -DefaultValue "N" -Format "Y/N" -Description "Fetch the latest features from GitHub." -HelpText @(" `$cGreen[!] A new update is available: v`$remoteVer`$cReset")
                                if (`$ans -eq 'ESC_CANCEL') { Add-Log "Update cancelled."; `$needsRefresh = `$true; break }
                                if (`$ans -match '^[Yy]') {
                                    Write-Host "`n   `$cAccent Confirming download... Launching Update Engine.`$cReset"
                                    `$updateCmd = "irm https://raw.githubusercontent.com/avm3005/detaroxzDarkSwitch/main/UpdSystem/setup.ps1 | iex"
                                    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"`$updateCmd`""
                                    exit
                                } else {
                                    Add-Log "Update cancelled."
                                }
                            } elseif ([version]"`$appVersion" -gt [version]`$remoteVer) {
                                Write-Host "`n   `$cRed[!] You shouldn't have this version, this is developer exclusive, FUCK OFF from here!!!`$cReset"
                                Start-Sleep -Seconds 3
                                Add-Log "Developer exclusive version detected."
                            } else {
                                Add-Log "You are on the latest version (v`$appVersion)."
                            }
                        } catch {
                            Add-Log "Failed to check for updates. Check your internet connection."
                        }
                        `$needsRefresh = `$true
                    }
                    "Open_Dev" { Start-Process "$devLink"; Add-Log "Opened Developer GitHub Profile" }
                    "Open_DevWeb" { Start-Process "$devWebsite"; Add-Log "Opened Developer Website" }
                    "Open_Proj" { Start-Process "$projectLink"; Add-Log "Opened Project GitHub Repository" }
                    "Open_Repos" { Start-Process "$moreProjectsLink"; Add-Log "Opened Developer Repositories Portfolio" }
                }
                [console]::CursorVisible = `$false
            }
        }
    }
} finally {
    Hide-Loading
    try { `$psCmd.Dispose(); `$rs.Dispose() } catch {}
    [console]::CursorVisible = `$true
    Clear-Host
}
"@
    Set-Content -Path $psSettingsPath -Value $settingsScriptContent -Force

    Write-Host "$e[36m[6/9] Generating Uninstaller...$e[0m"
    $uninstallScriptContent = @'
param([string]$MODE_FLAG)

$isUpgrade = ($MODE_FLAG -eq 'UPGRADE')
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $argsStr = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $MODE_FLAG"
    if ($isUpgrade) {
        Start-Process powershell.exe -Verb RunAs -ArgumentList $argsStr -WindowStyle Hidden
    } else {
        $hasWT = (Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe") -or [bool](Get-Item "$env:windir\System32\wt.exe" -ErrorAction SilentlyContinue)
        if ($hasWT) {
            Start-Process wt.exe -Verb RunAs -ArgumentList "powershell.exe $argsStr"
        } else {
            Start-Process powershell.exe -Verb RunAs -ArgumentList $argsStr
        }
    }
    exit
}

if (-not $isUpgrade) {
    $inWT = $null -ne $env:WT_SESSION
    if (-not $inWT -and $MODE_FLAG -ne 'WT_LAUNCHED') {
        $hasWT = (Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe") -or [bool](Get-Item "$env:windir\System32\wt.exe" -ErrorAction SilentlyContinue)
        if ($hasWT) {
            Start-Process wt.exe -ArgumentList "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" WT_LAUNCHED"
            exit
        }
    }

    Clear-Host
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Write-Host "`n===========================================================================" -ForegroundColor Cyan
    Write-Host " DARK SWITCH UNINSTALLER" -ForegroundColor Magenta
    Write-Host "===========================================================================`n" -ForegroundColor Cyan
    
    $delReg = Read-Host " -> Do you want to completely delete all saved preferences and settings? (Y/N) [Default: N]"
    
    Write-Host "`n Removing Dark Switch and restoring system settings..." -ForegroundColor Yellow

    $regDM = "HKCU:\SOFTWARE\DarkSwitch"
    $regData = Get-ItemProperty $regDM -ErrorAction SilentlyContinue
    
    if ($regData -and $regData.WallpaperEnabled -eq 1) {
        Write-Host " -> Restoring Backup Wallpaper settings before uninstalling..." -ForegroundColor DarkGray
        Set-ItemProperty -Path $regDM -Name "WallpaperEnabled" -Value 0 -Type DWord -Force
        
        $codeWP = @"
        using System; using System.Runtime.InteropServices; using Microsoft.Win32;
        public class WPTheme {
            [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
            [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)] public static extern void SHCreateItemFromParsingName([In][MarshalAs(UnmanagedType.LPWStr)] string pszPath, [In] IntPtr pbc, [In] ref Guid riid, out IntPtr ppv);
            [DllImport("shell32.dll", PreserveSig = false)] public static extern void SHCreateShellItemArrayFromShellItem([In] IntPtr psi, [In] ref Guid riid, out IntPtr ppv);

            [ComImport, Guid("43826d1e-e718-42ee-bc55-a1e261c37bfe"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] public interface IShellItem { }
            [ComImport, Guid("b63ea76d-1f85-456f-a19c-48159efa858b"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] public interface IShellItemArray { }

            [ComImport, Guid("C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD")] public class DesktopWallpaper { }
            
            [ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] 
            public interface IDesktopWallpaper {
                void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] string wallpaper);
                void GetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] out string wallpaper);
                void GetMonitorDevicePathAt(uint monitorIndex, [MarshalAs(UnmanagedType.LPWStr)] out string monitorID);
                void GetMonitorDevicePathCount(out uint count);
                void GetMonitorRECT([MarshalAs(UnmanagedType.LPWStr)] string monitorID, out IntPtr displayRect);
                void SetBackgroundColor(uint color);
                void GetBackgroundColor(out uint color);
                void SetPosition(uint position);
                void GetPosition(out uint position);
                void SetSlideshow(IntPtr items);
                void GetSlideshow(out IntPtr items);
                void SetSlideshowOptions(uint options, uint slideshowTick);
            }
            
            public static void ApplyWpMode(int mode, string file, string colorHex, string folder, int tick) {
                using (RegistryKey expWp = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers"))
                using (RegistryKey cpColors = Registry.CurrentUser.CreateSubKey(@"Control Panel\Colors")) {
                    if (mode == 2 && string.IsNullOrEmpty(folder)) { mode = 0; }
                    if (expWp != null) expWp.SetValue("BackgroundType", mode, RegistryValueKind.DWord);
                    
                    IDesktopWallpaper dw = null;
                    try { dw = (IDesktopWallpaper)new DesktopWallpaper(); } catch {}

                    if (mode == 0 && !string.IsNullOrEmpty(file)) {
                        try { if(dw != null) dw.SetWallpaper(null, file); } 
                        catch { SystemParametersInfo(20, 0, file, 3); }
                    }
                    else if (mode == 1 && !string.IsNullOrEmpty(colorHex)) {
                        string rgb = "0 0 0";
                        try {
                            string h = colorHex.StartsWith("#") ? colorHex.Substring(1) : colorHex;
                            int r = 0, g = 0, b = 0;
                            if(h.Length == 6) {
                                r = Convert.ToInt32(h.Substring(0,2), 16);
                                g = Convert.ToInt32(h.Substring(2,2), 16);
                                b = Convert.ToInt32(h.Substring(4,2), 16);
                            }
                            rgb = r + " " + g + " " + b;
                            uint color = (uint)(r | (g << 8) | (b << 16));
                            if(dw != null) { dw.SetWallpaper(null, ""); dw.SetBackgroundColor(color); }
                        } catch {}
                        if (cpColors != null) cpColors.SetValue("Background", rgb, RegistryValueKind.String);
                        SystemParametersInfo(20, 0, "", 3);
                    }
                    else if (mode == 2 && !string.IsNullOrEmpty(folder)) {
                        if (expWp != null) {
                            expWp.SetValue("SlideshowDirectoryPath1", folder, RegistryValueKind.String);
                            expWp.SetValue("SlideshowTick", tick, RegistryValueKind.DWord);
                        }
                        try {
                            if (dw != null) {
                                Guid iidShellItem = new Guid("43826d1e-e718-42ee-bc55-a1e261c37bfe");
                                IntPtr pItem = IntPtr.Zero;
                                SHCreateItemFromParsingName(folder, IntPtr.Zero, ref iidShellItem, out pItem);
                                
                                if (pItem != IntPtr.Zero) {
                                    Guid iidShellItemArray = new Guid("b63ea76d-1f85-456f-a19c-48159efa858b");
                                    IntPtr pArray = IntPtr.Zero;
                                    SHCreateShellItemArrayFromShellItem(pItem, ref iidShellItemArray, out pArray);

                                    if (pArray != IntPtr.Zero) {
                                        dw.SetSlideshow(pArray);
                                        dw.SetSlideshowOptions(0, (uint)tick);
                                        Marshal.Release(pArray);
                                    }
                                    Marshal.Release(pItem);
                                }
                            }
                        } catch { SystemParametersInfo(20, 0, "", 3); }
                    }
                }
            }

            public static void ApplyCursor() {
                using (RegistryKey cursors = Registry.CurrentUser.CreateSubKey(@"Control Panel\Cursors")) {
                    if (cursors != null) {
                        cursors.SetValue("", "Windows Default");
                        string[] keys = { "Arrow", "Help", "AppStarting", "Wait", "Crosshair", "IBeam", "NWPen", "No", "SizeNS", "SizeWE", "SizeNWSE", "SizeNESW", "SizeAll", "UpArrow", "Hand" };
                        foreach(string k in keys) cursors.DeleteValue(k, false);
                    }
                }
                SystemParametersInfo(0x0057, 0, null, 0x01 | 0x02);
            }
        }
"@
        if (-not ("WPTheme" -as [type])) { Add-Type -TypeDefinition $codeWP -ErrorAction SilentlyContinue }
        
        $bMode = $regData.BackupWpMode
        if ($null -ne $bMode) {
            $bFile = $regData.BackupWpFile
            $bColor = $regData.BackupWpColor
            $bFolder = $regData.BackupWpFolder
            $bTick = $regData.BackupWpInterval
            [WPTheme]::ApplyWpMode([int]$bMode, "$bFile", "$bColor", "$bFolder", [int]$bTick)
        } else {
            $wpDir = "C:\Program Files\Detaroxz\DarkSwitch\Wallpapers"
            $bWp = (Get-ChildItem "$wpDir\Default_WP.*" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
            if ($bWp -and (Test-Path $bWp)) { [WPTheme]::ApplyWpMode(0, $bWp, "", "", 600000) }
        }
    }

    if ($regData -and $regData.CursorEnabled -eq 1) {
        Write-Host " -> Restoring original Cursor settings before uninstalling..." -ForegroundColor DarkGray
        Set-ItemProperty -Path $regDM -Name "CursorEnabled" -Value 0 -Type DWord -Force
        if ("WPTheme" -as [type]) { [WPTheme]::ApplyCursor() }
    }
    
    if ($regData -and $regData.AccentEnabled -eq 1) {
        Write-Host " -> Restoring original Accent settings before uninstalling..." -ForegroundColor DarkGray
        Set-ItemProperty -Path $regDM -Name "AccentEnabled" -Value 0 -Type DWord -Force
        
        $codeAcc = @"
        using System; using System.Runtime.InteropServices; using Microsoft.Win32;
        public class AccTheme {
            [StructLayout(LayoutKind.Sequential)]
            public struct IMMERSIVE_COLOR_PREFERENCE {
                public uint dwColorSpace;
                public uint dwColor;
            }

            [DllImport("uxtheme.dll", EntryPoint = "#122")]
            public static extern int SetUserColorPreference(ref IMMERSIVE_COLOR_PREFERENCE pcpPreference, bool fForceCommit);

            [DllImport("uxtheme.dll", EntryPoint = "#104")] public static extern void RefreshImmersiveColorPolicyState();
            [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
            [DllImport("shell32.dll", CharSet = CharSet.Auto)] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
            
            public static void Restore(int autoCol, long accColLong) {
                int accCol = unchecked((int)accColLong);

                try {
                    if (autoCol == 0) {
                        IMMERSIVE_COLOR_PREFERENCE pref = new IMMERSIVE_COLOR_PREFERENCE();
                        pref.dwColorSpace = 0;
                        pref.dwColor = unchecked((uint)accCol);
                        SetUserColorPreference(ref pref, true);
                    }
                } catch {}

                using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { 
                    if (desk != null) { desk.SetValue("AutoColorization", autoCol, RegistryValueKind.DWord); desk.Flush(); }
                }
                using (RegistryKey dwm = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\DWM")) { 
                    if (dwm != null) {
                        dwm.SetValue("AccentColor", accCol, RegistryValueKind.DWord); 
                        dwm.SetValue("ColorizationColor", accCol | unchecked((int)0xFF000000), RegistryValueKind.DWord);
                        dwm.Flush();
                    }
                }
                using (RegistryKey accent = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Explorer\Accent")) {
                    if (accent != null) {
                        accent.SetValue("AccentColorMenu", accCol, RegistryValueKind.DWord);
                        accent.SetValue("StartColorMenu", accCol, RegistryValueKind.DWord);

                        int r = accCol & 0xFF; int g = (accCol >> 8) & 0xFF; int b = (accCol >> 16) & 0xFF;
                        byte[] palette = new byte[32];
                        for (int i = 0; i < 8; i++) {
                            palette[i * 4] = (byte)r; palette[i * 4 + 1] = (byte)g; palette[i * 4 + 2] = (byte)b; palette[i * 4 + 3] = 0;
                        }
                        accent.SetValue("AccentPalette", palette, RegistryValueKind.Binary);
                        accent.Flush();
                    }
                }
                RefreshImmersiveColorPolicyState();
                IntPtr res;
                SendMessageTimeout((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "ImmersiveColorSet", 0x0000, 500, out res);
                try { SHChangeNotify(0x08000000, 0x0000, IntPtr.Zero, IntPtr.Zero); } catch {}
            }
        }
"@
        if (-not ("AccTheme" -as [type])) { Add-Type -TypeDefinition $codeAcc -ErrorAction SilentlyContinue }
        
        $bAuto = $regData.BackupAutoCol
        $bAcc = $regData.BackupAccCol
        if ($null -ne $bAuto -and $null -ne $bAcc) {
            try { [AccTheme]::Restore([int]$bAuto, [long]$bAcc) } catch {}
        }
    }

    Write-Host " -> Unregistering scheduled tasks..." -ForegroundColor DarkGray
    Get-ScheduledTask -TaskName "DarkSwitch*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

    Write-Host " -> Removing Start Menu shortcuts..." -ForegroundColor DarkGray
    $startMenu = [Environment]::GetFolderPath("CommonApplicationData") + "\Microsoft\Windows\Start Menu\Programs\DarkSwitch"
    $legacyStartMenu = [Environment]::GetFolderPath("ApplicationData") + "\Microsoft\Windows\Start Menu\Programs\DarkSwitch"
    if (Test-Path $startMenu) { Remove-Item -Path $startMenu -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $legacyStartMenu) { Remove-Item -Path $legacyStartMenu -Recurse -Force -ErrorAction SilentlyContinue }

    Start-Sleep -Seconds 1
    $sig = '[DllImport("shell32.dll", CharSet=CharSet.Auto)] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);'
    if (-not ("Shell.WinAPI" -as [type])) { Add-Type -MemberDefinition $sig -Name WinAPI -Namespace Shell -PassThru | Out-Null }
    [Shell.WinAPI]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
    
    Write-Host " -> Cleaning up Registry entries..." -ForegroundColor DarkGray
    $uninstallRegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\DarkSwitch"
    if (Test-Path $uninstallRegKey) { Remove-Item -Path $uninstallRegKey -Force -Recurse -ErrorAction SilentlyContinue }

    if ($delReg -match '^[Yy]') {
        Write-Host " -> Cleaning up User Preferences..." -ForegroundColor DarkGray
        if (Test-Path $regDM) { Remove-Item $regDM -Force -Recurse -ErrorAction SilentlyContinue }
    }

    Write-Host " -> Removing Environment Path variables..." -ForegroundColor DarkGray
    $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    if ($userPath -match [regex]::Escape("C:\Program Files\Detaroxz\DarkSwitch")) {
        $newPath = ($userPath -split ';' | Where-Object { $_ -ne "C:\Program Files\Detaroxz\DarkSwitch" -and $_ -ne "" }) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)
        $code = '[DllImport("user32.dll",CharSet=CharSet.Auto)]public static extern IntPtr SendMessageTimeout(IntPtr h,uint m,IntPtr w,string l,uint f,uint t,out IntPtr r);'
        if (-not ("Win32.EnvRefresher" -as [type])) { Add-Type -MemberDefinition $code -Name "EnvRefresher" -Namespace "Win32" -PassThru | Out-Null }
        $res = [IntPtr]::Zero; [Win32.EnvRefresher]::SendMessageTimeout([IntPtr]0xFFFF, 0x001A, [IntPtr]0, "Environment", 2, 1000, [ref]$res) | Out-Null
    }

    Write-Host " -> Queuing final directory deletion..." -ForegroundColor DarkGray
    $targetDir = "C:\Program Files\Detaroxz\DarkSwitch"
    $parentDir = "C:\Program Files\Detaroxz"
    $pidToWait = $PID
    
    # Clean the directory, and if the parent Detaroxz is empty, remove that too
    $cmdCleanup = "Wait-Process -Id $pidToWait -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2; Remove-Item -Path '$targetDir' -Recurse -Force -ErrorAction SilentlyContinue; if ((Get-ChildItem '$parentDir' -ErrorAction SilentlyContinue).Count -eq 0) { Remove-Item -Path '$parentDir' -Force -ErrorAction SilentlyContinue }"
    Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -Command `"$cmdCleanup`"" -WindowStyle Hidden

    Write-Host "`n===========================================================================" -ForegroundColor Cyan
    Write-Host " Dark Switch has been successfully uninstalled from your system." -ForegroundColor Green
    Write-Host "===========================================================================`n" -ForegroundColor Cyan
    
    Write-Host "Press ENTER to exit..." -ForegroundColor Yellow
    Read-Host
}

exit 0
'@
    Set-Content -Path $psUninstallPath -Value $uninstallScriptContent -Force

    Write-Host "$e[36m[7/9] Registering CLI Alias (darkswitch)...$e[0m"
    # Small cmd script to proxy seamlessly when typing 'darkswitch' in Win+R or CMD without extensions
    $cliScriptContent = @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0DarkSwitch-Core.ps1" %*
"@
    Set-Content -Path "$targetDir\darkswitch.cmd" -Value $cliScriptContent -Force

    $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    if ($userPath -notmatch [regex]::Escape($targetDir)) {
        $separator = if ($userPath.EndsWith(";") -or [string]::IsNullOrEmpty($userPath)) { "" } else { ";" }
        $newPath = $userPath + $separator + $targetDir
        [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)
        
        $code = '[DllImport("user32.dll",CharSet=CharSet.Auto)]public static extern IntPtr SendMessageTimeout(IntPtr h,uint m,IntPtr w,string l,uint f,uint t,out IntPtr r);'
        if (-not ("Win32.EnvRefresher" -as [type])) { Add-Type -MemberDefinition $code -Name "EnvRefresher" -Namespace "Win32" -PassThru | Out-Null }
        $res = [IntPtr]::Zero; [Win32.EnvRefresher]::SendMessageTimeout([IntPtr]0xFFFF, 0x001A, [IntPtr]0, "Environment", 2, 1000, [ref]$res) | Out-Null
    }

    Write-Host "$e[36m[8/9] Registering App in Settings (Control Panel)...$e[0m"
    if (-not (Test-Path $uninstallRegKey)) { New-Item -Path $uninstallRegKey -Force | Out-Null }
    Set-ItemProperty -Path $uninstallRegKey -Name "DisplayName" -Value "Dark Switch"
    Set-ItemProperty -Path $uninstallRegKey -Name "DisplayVersion" -Value "$appVersion"
    Set-ItemProperty -Path $uninstallRegKey -Name "Publisher" -Value $devName
    Set-ItemProperty -Path $uninstallRegKey -Name "HelpLink" -Value $devLink
    Set-ItemProperty -Path $uninstallRegKey -Name "URLInfoAbout" -Value $projectLink
    if (Test-Path "$resourceDir\main.ico") { Set-ItemProperty -Path $uninstallRegKey -Name "DisplayIcon" -Value "$resourceDir\main.ico, 0" }
    
    # Updated uninstall string to launch silently through VBS runner, preventing the initial console flash. 
    # It delegates visible Terminal elevation entirely to Uninstall.ps1
    Set-ItemProperty -Path $uninstallRegKey -Name "UninstallString" -Value "wscript.exe `"$vbsRunnerPath`" `"$psUninstallPath`""
    Set-ItemProperty -Path $uninstallRegKey -Name "NoModify" -Value 1
    Set-ItemProperty -Path $uninstallRegKey -Name "NoRepair" -Value 1

    Write-Host "$e[36m[9/9] Creating Start Menu Shortcuts & Registering Tasks...$e[0m"
    $WshShell = New-Object -ComObject WScript.Shell
    
    $shortcutSettings = $WshShell.CreateShortcut("$startMenuPath\Core.lnk")
    $hasWT = (Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe") -or [bool](Get-Item "$env:windir\System32\wt.exe" -ErrorAction SilentlyContinue)
    if ($hasWT) {
        $shortcutSettings.TargetPath = "wt.exe"
        $shortcutSettings.Arguments = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$psSettingsPath`""
    } else {
        $shortcutSettings.TargetPath = "powershell.exe"
        $shortcutSettings.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$psSettingsPath`""
    }
    $shortcutSettings.WorkingDirectory = $targetDir
    if (Test-Path "$resourceDir\main.ico") { $shortcutSettings.IconLocation = "$resourceDir\main.ico, 0" }
    $shortcutSettings.Save()

    try {
        $bytes = [System.IO.File]::ReadAllBytes("$startMenuPath\Core.lnk")
        $bytes[0x15] = $bytes[0x15] -bor 0x20
        [System.IO.File]::WriteAllBytes("$startMenuPath\Core.lnk", $bytes)
    } catch {}

    $shortcutToggle = $WshShell.CreateShortcut("$startMenuPath\Quick Toggle.lnk")
    $shortcutToggle.TargetPath = "$env:windir\System32\wscript.exe"
    $shortcutToggle.Arguments = "`"$engineDir\Toggle.vbs`""
    $shortcutToggle.WorkingDirectory = $engineDir
    $shortcutToggle.WindowStyle = 7
    if (Test-Path "$resourceDir\qt.ico") { $shortcutToggle.IconLocation = "$resourceDir\qt.ico, 0" }
    $shortcutToggle.Save()

    if ($enableShortcut -match '^[Yy]') { 
        Start-Sleep -Milliseconds 200
        $shortcutToggle.Hotkey = "Ctrl+Alt+$shortcutKey" 
        $shortcutToggle.Save()
    }
    
    Start-Sleep -Seconds 2
    $sig = '[DllImport("shell32.dll", CharSet=CharSet.Auto)] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);'
    if (-not ("Shell.WinAPI" -as [type])) { Add-Type -MemberDefinition $sig -Name WinAPI -Namespace Shell -PassThru | Out-Null }
    [Shell.WinAPI]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)

    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 1) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    function Get-TaskAction ($Type) {
        if ($Type -eq 'TOGGLE') {
            return New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$engineDir\Toggle.vbs`""
        } else {
            $file = "CoreEngine.ps1"
            $arg = " $Type"
            return New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$vbsRunnerPath`" `"$engineDir\$file`"$arg"
        }
    }

    $actionSyncLight = Get-TaskAction "SYNC_LIGHT"
    $actionSyncDark  = Get-TaskAction "SYNC_DARK"
    $actionBoot = Get-TaskAction "BOOT"
    $actionSunMode  = Get-TaskAction "SUN"
    
    try { $ptL = Get-Date $lightTime } catch { $ptL = (Get-Date).Date.AddHours(7) }
    $taskLight = New-ScheduledTask -Action $actionSyncLight -Principal $principal -Trigger (New-ScheduledTaskTrigger -Daily -At $ptL) -Settings $settings
    try { Register-ScheduledTask -TaskName "DarkSwitch - Light Mode" -TaskPath $tPath -InputObject $taskLight -Force -ErrorAction Stop | Out-Null } catch {}
    Set-TaskPriority -TaskName "DarkSwitch - Light Mode" -Priority 2

    try { $ptD = Get-Date $darkTime } catch { $ptD = (Get-Date).Date.AddHours(19) }
    $taskDark = New-ScheduledTask -Action $actionSyncDark -Principal $principal -Trigger (New-ScheduledTaskTrigger -Daily -At $ptD) -Settings $settings
    try { Register-ScheduledTask -TaskName "DarkSwitch - Dark Mode" -TaskPath $tPath -InputObject $taskDark -Force -ErrorAction Stop | Out-Null } catch {}
    Set-TaskPriority -TaskName "DarkSwitch - Dark Mode" -Priority 2

    Register-ScheduledTask -TaskName "DarkSwitch - Boot Sync" -TaskPath $tPath -Action $actionBoot -Principal $principal -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Settings $settings -Force -ErrorAction SilentlyContinue | Out-Null
    $xmlBoot = try { Export-ScheduledTask -TaskName "DarkSwitch - Boot Sync" -TaskPath $tPath -ErrorAction Stop | Out-String } catch { $null }
    if ($xmlBoot) {
        $xmlBoot = $xmlBoot -replace '</Triggers>', '<SessionStateChangeTrigger><StateChange>SessionUnlock</StateChange></SessionStateChangeTrigger></Triggers>'
        if ($xmlBoot -match '<Priority>\s*\d+\s*</Priority>') { $xmlBoot = $xmlBoot -replace '<Priority>\s*\d+\s*</Priority>', "<Priority>2</Priority>" } 
        else { $xmlBoot = $xmlBoot -replace '</Settings>', "  <Priority>2</Priority>`n  </Settings>" }
        try { Register-ScheduledTask -TaskName "DarkSwitch - Boot Sync" -TaskPath $tPath -Xml $xmlBoot -Force -User $env:USERNAME -ErrorAction Stop | Out-Null } catch {}
    }

    $actionToggleMode = Get-TaskAction "TOGGLE"
    Register-ScheduledTask -TaskName "DarkSwitch - Quick Toggle" -TaskPath $tPath -Action $actionToggleMode -Principal $principal -Settings $settings -Force -ErrorAction SilentlyContinue | Out-Null
    Set-TaskPriority -TaskName "DarkSwitch - Quick Toggle" -Priority 0

    if ($dynSun -eq "Y") {
        $sunTimeVal = if ($config.ContainsKey("SunTime")) { $config["SunTime"] } else { "00:00" }
        $safeTime = if ([string]::IsNullOrWhiteSpace($sunTimeVal)) { "00:00" } else { $sunTimeVal.Trim() }
        try { $pt = Get-Date $safeTime } catch { $pt = (Get-Date).Date }
        $sunTrigs = @(New-ScheduledTaskTrigger -Daily -At $pt)
        if ($sunSyncBoot -eq "Y") { $sunTrigs += New-ScheduledTaskTrigger -AtLogOn }
        
        $taskSun = New-ScheduledTask -Action $actionSunMode -Principal $principal -Trigger $sunTrigs -Settings $settings
        try { Register-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath $tPath -InputObject $taskSun -Force -ErrorAction Stop | Out-Null } catch {}
        
        $xmlSun = try { Export-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath $tPath -ErrorAction Stop | Out-String } catch { $null }
        if ($xmlSun) {
            if ($sunSyncBoot -eq "Y") { $xmlSun = $xmlSun -replace '</Triggers>', '<SessionStateChangeTrigger><StateChange>SessionUnlock</StateChange></SessionStateChangeTrigger></Triggers>' }
            if ($xmlSun -match '<Priority>\s*\d+\s*</Priority>') { $xmlSun = $xmlSun -replace '<Priority>\s*\d+\s*</Priority>', "<Priority>2</Priority>" } 
            else { $xmlSun = $xmlSun -replace '</Settings>', "  <Priority>2</Priority>`n  </Settings>" }
            try { Register-ScheduledTask -TaskName "DarkSwitch - Sun Update" -TaskPath $tPath -Xml $xmlSun -Force -User $env:USERNAME -ErrorAction Stop | Out-Null } catch {}
        }
        
        # Fire initial calculation asynchronously to set up exact times right now
        Start-Process -FilePath "wscript.exe" -ArgumentList "`"$vbsRunnerPath`" `"$coreEnginePath`" SUN" -WindowStyle Hidden -ErrorAction SilentlyContinue
    } else {
        # Fire initial sync asynchronously to apply the scheduled theme right now
        Start-Process -FilePath "wscript.exe" -ArgumentList "`"$vbsRunnerPath`" `"$coreEnginePath`" SYNC" -WindowStyle Hidden -ErrorAction SilentlyContinue
    }

    if ($enableBoot -notmatch '^[Yy]') { try { Disable-ScheduledTask -TaskName "DarkSwitch - Boot Sync" -TaskPath $tPath -ErrorAction Stop | Out-Null } catch {} }

} catch {
    Write-Host "`n$e[1;31m[CRITICAL ERROR LOG]$e[0m"
    Write-Host $_.Exception.Message -ForegroundColor Red
    Invoke-Rollback
}

$ErrorActionPreference = "Continue"

Write-Host "`n$cMain===========================================================================$cReset"
Write-Host " $cGreen INSTALLATION COMPLETE! $cReset"
Write-Host "$cMain===========================================================================$cReset"
Write-Host "`nYou can now find $e[1;36mCore$e[0m in your Windows Start Menu.`n"

Write-Host "Press $e[1m'C'$e[0m to launch Dark Switch Core, $e[1m'V'$e[0m for Developer's GitHub, or $e[1mENTER$e[0m to exit."
$key = [System.Console]::ReadKey($true)
if ($key.Key -eq 'C') {
    $hasWT = (Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe") -or [bool](Get-Item "$env:windir\System32\wt.exe" -ErrorAction SilentlyContinue)
    if ($hasWT) {
        Start-Process wt.exe -ArgumentList "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$psSettingsPath`""
    } else {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$psSettingsPath`""
    }
} elseif ($key.Key -eq 'V') { 
    Start-Process $devLink 
}

exit