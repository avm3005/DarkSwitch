# 2>NUL & @echo off
# 2>NUL & set "SELF_PATH=%~f0"
# 2>NUL & set "LAUNCH_MODE=%~1"
# 2>NUL & net session >nul 2>&1 || (powershell -NoProfile -WindowStyle Hidden -Command "Start-Process cmd -ArgumentList '/c \"\"%SELF_PATH%\"\" %LAUNCH_MODE%' -Verb RunAs" & exit /b)
# 2>NUL & if /I "%LAUNCH_MODE%"=="UI" if not defined WT_SESSION (wt powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))" & exit /b)
# 2>NUL & powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))"
# 2>NUL & exit /b

$e = [char]27
$smPath = [Environment]::GetFolderPath("CommonApplicationData") + "\Microsoft\Windows\Start Menu\Programs\AutoDM"
$p = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

$is24Hour = (Get-Culture).DateTimeFormat.ShortTimePattern -cmatch 'H'
$timeFormat = if ($is24Hour) { "HH:mm" } else { "h:mm tt" }
$timeHint = if ($is24Hour) { "HH:MM (e.g., 07:00, 19:30)" } else { "HH:MM AM/PM" }

$WshShell = New-Object -ComObject WScript.Shell
$scTogglePath = "$smPath\Quick Toggle.lnk"

# --- INITIAL MEMORY CACHE & ANIMATED LOADING ---
if ($env:LAUNCH_MODE -eq "UI") { Clear-Host }
Write-Host ""
Write-Host "
$e[1;36mLoading   $e[0m" -NoNewline

$tasks = Get-ScheduledTask -TaskName "AutoDM*" -ErrorAction SilentlyContinue
$tLight = $tasks | Where-Object TaskName -eq "AutoDM - Light Mode"
$tDark = $tasks | Where-Object TaskName -eq "AutoDM - Dark Mode"
$tBoot = $tasks | Where-Object TaskName -eq "AutoDM - Boot Sync"

Write-Host "
$e[1;36mLoading.  $e[0m" -NoNewline
Start-Sleep -Milliseconds 100

$lTime = if ($tLight) { [datetime]::Parse($tLight.Triggers[0].StartBoundary).ToString($timeFormat) } else { "N/A" }
$dTime = if ($tDark) { [datetime]::Parse($tDark.Triggers[0].StartBoundary).ToString($timeFormat) } else { "N/A" }
$tLightState = if ($tLight) { $tLight.State } else { 'Disabled' }
$tBootState = if ($tBoot) { $tBoot.State } else { 'Disabled' }

Write-Host "
$e[1;36mLoading.. $e[0m" -NoNewline
Start-Sleep -Milliseconds 100

$isSmHidden = $false
if (Test-Path $smPath) { $isSmHidden = ((Get-Item $smPath -Force).Attributes -band [System.IO.FileAttributes]::Hidden) -eq [System.IO.FileAttributes]::Hidden }
$scToggle = $WshShell.CreateShortcut($scTogglePath)
$hotkey = $scToggle.Hotkey
$hkEnabled = [bool]$hotkey

Write-Host "
$e[1;36mLoading...$e[0m" -NoNewline

if (-not ("Shell.WinAPI" -as [type])) {
    $sig = '[DllImport("shell32.dll", CharSet=CharSet.Auto)] public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);'
    Add-Type -MemberDefinition $sig -Name WinAPI -Namespace Shell -PassThru | Out-Null
}

Start-Sleep -Milliseconds 150
$sessionLog = @()

function Get-ValidTime ($Prompt) {
    while ($true) {
        $timeStr = Read-Host "$e[3m$Prompt ($timeHint)$e[0m"
        try { return [datetime]::Parse($timeStr).ToString($timeFormat) } 
        catch { Write-Host "  -> Invalid format.
" -ForegroundColor Red }
    }
}

while ($true) {
    if ($env:LAUNCH_MODE -eq "UI") { Clear-Host }
    Write-Host "
$e[1;38;5;51m========================================$e[0m"
    Write-Host "$e[1;38;5;213m   AutoDM v1.3.1 Dashboard by detaroxz  $e[0m"
    Write-Host "$e[1;38;5;51m========================================$e[0m
"
    
    if ($sessionLog.Count -gt 0) {
        Write-Host "$e[33m--- Session Log ---$e[0m"
        foreach ($log in $sessionLog) { Write-Host " > $log" -ForegroundColor Green }
        Write-Host ""
    }

    $autoStatus = if ($tLightState -ne 'Disabled') { "$e[1;38;5;46mEnabled$e[0m" } else { "$e[1;38;5;196mDisabled$e[0m" }
    $bootStatus = if ($tBootState -ne 'Disabled') { "$e[1;38;5;46mEnabled$e[0m" } else { "$e[1;38;5;196mDisabled$e[0m" }
    $smStatus = if ($isSmHidden) { "$e[1;38;5;196mHidden$e[0m" } else { "$e[1;38;5;46mVisible$e[0m" }
    $hkStatus = if ($hkEnabled) { "$e[1;38;5;46mEnabled$e[0m" } else { "$e[1;38;5;196mDisabled$e[0m" }

    Write-Host "$e[1m1.$e[0m Change Light Mode Time    (Current: $e[33m$lTime$e[0m)"
    Write-Host "$e[1m2.$e[0m Change Dark Mode Time     (Current: $e[33m$dTime$e[0m)"
    Write-Host "$e[1m3.$e[0m Toggle Boot Trigger       (Current: $bootStatus)"
    Write-Host "$e[1m4.$e[0m Toggle Auto Switching     (Current: $autoStatus)"
    Write-Host "$e[1m5.$e[0m Toggle Start Menu Items   (Current: $smStatus)"
    Write-Host "$e[1m6.$e[0m Toggle Keyboard Shortcut  (Current: $hkStatus)"
    
    $optDev = 7
    if ($hkEnabled) {
        Write-Host "$e[1m7.$e[0m Change Shortcut Key       (Current: $e[33m$hotkey$e[0m)"
        $optDev = 8
    }
    $optProj = $optDev + 1
    
    Write-Host "$e[1m$optDev.$e[0m Visit Developer on Github"
    Write-Host "$e[1m$optProj.$e[0m Visit Project on Github"
    Write-Host "$e[90m(Press any other key to exit)$e[0m
"

    $choice = Read-Host "$e[1;36mSelect an option$e[0m"

    switch ($choice) {
        '1' {
            $newLight = Get-ValidTime "Enter NEW LIGHT mode time"
            $trigger = New-ScheduledTaskTrigger -Daily -At $newLight
            Set-ScheduledTask -TaskName "AutoDM - Light Mode" -Trigger $trigger -Principal $p | Out-Null
            $lTime = $newLight
            $sessionLog += "Light mode time updated to $newLight"
        }
        '2' {
            $newDark = Get-ValidTime "Enter NEW DARK mode time"
            $trigger = New-ScheduledTaskTrigger -Daily -At $newDark
            Set-ScheduledTask -TaskName "AutoDM - Dark Mode" -Trigger $trigger -Principal $p | Out-Null
            $dTime = $newDark
            $sessionLog += "Dark mode time updated to $newDark"
        }
        '3' {
            if ($tBootState -ne 'Disabled') { Disable-ScheduledTask -TaskName "AutoDM - Boot Sync" | Out-Null; $tBootState = 'Disabled'; $sessionLog += "Boot trigger disabled" } 
            else { Enable-ScheduledTask -TaskName "AutoDM - Boot Sync" | Out-Null; $tBootState = 'Ready'; $sessionLog += "Boot trigger enabled" }
        }
        '4' {
            if ($tLightState -ne 'Disabled') {
                Disable-ScheduledTask -TaskName "AutoDM - Light Mode" | Out-Null; Disable-ScheduledTask -TaskName "AutoDM - Dark Mode" | Out-Null
                $tLightState = 'Disabled'
                $sessionLog += "Auto switching disabled"
            } else {
                Enable-ScheduledTask -TaskName "AutoDM - Light Mode" | Out-Null; Enable-ScheduledTask -TaskName "AutoDM - Dark Mode" | Out-Null
                $tLightState = 'Ready'
                $sessionLog += "Auto switching enabled"
            }
        }
        '5' {
            if (Test-Path $smPath) {
                $item = Get-Item $smPath -Force
                if ($isSmHidden) { 
                    $item.Attributes = $item.Attributes -band (-bnot [System.IO.FileAttributes]::Hidden)
                    $isSmHidden = $false
                    $sessionLog += "Start menu items set to Visible"
                } else { 
                    $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
                    $isSmHidden = $true
                    $sessionLog += "Start menu items set to Hidden"
                }
                
                # Give Indexer time to catch attribute change
                Start-Sleep -Seconds 2
                [Shell.WinAPI]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
                Stop-Process -Name "SearchHost" -Force -ErrorAction SilentlyContinue
                Stop-Process -Name "StartMenuExperienceHost" -Force -ErrorAction SilentlyContinue
            }
        }
        '6' {
            $regPath = "HKCU:\SOFTWARE\AutoDM"
            $savedKey = if (Test-Path $regPath) { (Get-ItemProperty $regPath -Name "ShortcutKey" -ErrorAction SilentlyContinue).ShortcutKey } else { $null }
            if (-not $savedKey) { $savedKey = "T" }

            if ($hkEnabled) { 
                $scToggle.Hotkey = ""; $scToggle.Save() 
                $hkEnabled = $false
                $hotkey = ""
                $sessionLog += "Keyboard shortcut disabled"
            } else { 
                $scToggle.Hotkey = ""; $scToggle.Save()
                Start-Sleep -Milliseconds 200
                $scToggle.Hotkey = "CTRL+ALT+" + $savedKey; $scToggle.Save() 
                $hkEnabled = $true
                $hotkey = "CTRL+ALT+" + $savedKey
                $sessionLog += "Keyboard shortcut enabled ($hotkey)"
            }
        }
        default {
            if ($choice -eq '7' -and $hkEnabled) {
                while ($true) {
                    Write-Host ""
                    $newK = Read-Host "Enter new key to use with CTRL+ALT (A-Z, 0-9)"
                    if ($newK -match '^[a-zA-Z0-9]$') { 
                        $nk = $newK.ToUpper()
                        $hotkey = "CTRL+ALT+" + $nk
                        $scToggle.Hotkey = ""; $scToggle.Save()
                        Start-Sleep -Milliseconds 200
                        $scToggle.Hotkey = $hotkey
                        $scToggle.Save()
                        if (-not (Test-Path "HKCU:\SOFTWARE\AutoDM")) { New-Item "HKCU:\SOFTWARE\AutoDM" -Force | Out-Null }
                        Set-ItemProperty -Path "HKCU:\SOFTWARE\AutoDM" -Name "ShortcutKey" -Value $nk
                        $sessionLog += "Shortcut key updated to $hotkey"
                        break 
                    }
                    Write-Host "  -> Invalid key. Use a single letter or number.
" -ForegroundColor Red
                }
            } elseif (($choice -eq '7' -and -not $hkEnabled) -or ($choice -eq '8' -and $hkEnabled)) {
                Start-Process "https://github.com/avm3005/"; $sessionLog += "Opened Developer GitHub Profile"
            } elseif (($choice -eq '8' -and -not $hkEnabled) -or ($choice -eq '9' -and $hkEnabled)) {
                Start-Process "https://github.com/avm3005/detaroxzAutoDM"; $sessionLog += "Opened Project GitHub Repository"
            } else { exit }
        }
    }
}
