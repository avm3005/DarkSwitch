# 2>NUL & @cls & @echo off
# 2>NUL & set "SELF_PATH=%~f0"
# 2>NUL & net session >nul 2>&1 || (powershell -NoProfile -WindowStyle Hidden -Command "Start-Process cmd -ArgumentList '/c \"\"%SELF_PATH%\"\"' -Verb RunAs" & exit /b)
# 2>NUL & if not defined WT_SESSION (wt powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))" & exit /b)
# 2>NUL & powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))"
# 2>NUL & exit /b

$e = [char]27
$smPath = [Environment]::GetFolderPath("ApplicationData") + "\Microsoft\Windows\Start Menu\Programs\AutoDM"
$runKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"

$is24Hour = (Get-Culture).DateTimeFormat.ShortTimePattern -cmatch 'H'
$timeFormat = if ($is24Hour) { "HH:mm" } else { "h:mm tt" }
$timeHint = if ($is24Hour) { "HH:MM (e.g., 07:00, 19:30)" } else { "HH:MM AM/PM" }

function Get-ValidTime ($Prompt) {
    while ($true) {
        $timeStr = Read-Host "$e[3m$Prompt ($timeHint)$e[0m"
        try { return [datetime]::Parse($timeStr).ToString($timeFormat) } 
        catch { Write-Host "  -> Invalid format.
" -ForegroundColor Red }
    }
}

while ($true) {
    Clear-Host
    Write-Host "$e[1;38;5;51m========================================$e[0m"
    Write-Host "$e[1;38;5;213m   AutoDM v1.2.1 Dashboard by detaroxz  $e[0m"
    Write-Host "$e[1;38;5;51m========================================$e[0m
"
    
    $tLight = Get-ScheduledTask -TaskName "AutoDM - Light Mode" -ErrorAction SilentlyContinue
    $tDark = Get-ScheduledTask -TaskName "AutoDM - Dark Mode" -ErrorAction SilentlyContinue
    $tSync = Get-ItemProperty -Path $runKey -Name "AutoDM" -ErrorAction SilentlyContinue

    $lTime = if ($tLight) { [datetime]::Parse($tLight.Triggers[0].StartBoundary).ToString($timeFormat) } else { "N/A" }
    $dTime = if ($tDark) { [datetime]::Parse($tDark.Triggers[0].StartBoundary).ToString($timeFormat) } else { "N/A" }

    $autoStatus = if ($tLight.State -ne 'Disabled') { "$e[1;38;5;46mEnabled$e[0m" } else { "$e[1;38;5;196mDisabled$e[0m" }
    $syncStatus = if ($tSync) { "$e[1;38;5;46mEnabled$e[0m" } else { "$e[1;38;5;196mDisabled$e[0m" }
    
    $isSmHidden = $false
    if (Test-Path $smPath) { $isSmHidden = ((Get-Item $smPath -Force).Attributes -band [System.IO.FileAttributes]::Hidden) -eq [System.IO.FileAttributes]::Hidden }
    $smStatus = if ($isSmHidden) { "$e[1;38;5;196mHidden$e[0m" } else { "$e[1;38;5;46mVisible$e[0m" }

    Write-Host "$e[1m1.$e[0m Change Light Mode Time   (Current: $e[33m$lTime$e[0m)"
    Write-Host "$e[1m2.$e[0m Change Dark Mode Time    (Current: $e[33m$dTime$e[0m)"
    Write-Host "$e[1m3.$e[0m Toggle Startup Item      (Current: $syncStatus)"
    Write-Host "$e[1m4.$e[0m Toggle Auto Switching    (Current: $autoStatus)"
    Write-Host "$e[1m5.$e[0m Toggle Start Menu Vis.   (Current: $smStatus)"
    Write-Host "$e[1m6.$e[0m Visit Developer on Github"
    Write-Host "$e[1m7.$e[0m Visit Developer Website"
    Write-Host "$e[1m8.$e[0m Visit Project on Github"
    Write-Host "$e[1m9.$e[0m Exit Dashboard
"

    $choice = Read-Host "$e[1;36mSelect an option (1-9)$e[0m"

    switch ($choice) {
        '1' {
            $newLight = Get-ValidTime "Enter NEW LIGHT mode time"
            $trigger = New-ScheduledTaskTrigger -Daily -At $newLight
            Set-ScheduledTask -TaskName "AutoDM - Light Mode" -Trigger $trigger | Out-Null
            Write-Host "Updated!" -ForegroundColor Green; Start-Sleep -Seconds 1
        }
        '2' {
            $newDark = Get-ValidTime "Enter NEW DARK mode time"
            $trigger = New-ScheduledTaskTrigger -Daily -At $newDark
            Set-ScheduledTask -TaskName "AutoDM - Dark Mode" -Trigger $trigger | Out-Null
            Write-Host "Updated!" -ForegroundColor Green; Start-Sleep -Seconds 1
        }
        '3' {
            $myDir = Split-Path $env:SELF_PATH
            $vbsRunner = "$myDir\Engine\RunSilent.vbs"
            $syncScript = "$myDir\Engine\SyncTheme.cmd"
            if (Get-ItemProperty -Path $runKey -Name "AutoDM" -ErrorAction SilentlyContinue) { 
                Remove-ItemProperty -Path $runKey -Name "AutoDM" | Out-Null 
            } else { 
                Set-ItemProperty -Path $runKey -Name "AutoDM" -Value "wscript.exe "$vbsRunner" "$syncScript"" | Out-Null 
            }
            Write-Host "Toggled Windows Startup Item." -ForegroundColor Yellow; Start-Sleep -Seconds 1
        }
        '4' {
            if ($tLight.State -ne 'Disabled') {
                Disable-ScheduledTask -TaskName "AutoDM - Light Mode" | Out-Null; Disable-ScheduledTask -TaskName "AutoDM - Dark Mode" | Out-Null
            } else {
                Enable-ScheduledTask -TaskName "AutoDM - Light Mode" | Out-Null; Enable-ScheduledTask -TaskName "AutoDM - Dark Mode" | Out-Null
            }
            Write-Host "Toggled." -ForegroundColor Yellow; Start-Sleep -Seconds 1
        }
        '5' {
            if (Test-Path $smPath) {
                $item = Get-Item $smPath -Force
                if ($isSmHidden) { $item.Attributes = $item.Attributes -band (-bnot [System.IO.FileAttributes]::Hidden) } 
                else { $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden }
            }
            Start-Sleep -Seconds 1
        }
        '6' { Start-Process "https://github.com/avm3005/" }
        '7' { Start-Process "https://knowaboutarchit.xo.je/" }
        '8' { Start-Process "https://github.com/avm3005/detaroxzAutoDM" }
        '9' { exit }
    }
}
