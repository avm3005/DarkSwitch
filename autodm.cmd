@echo off
if /I "%~1"=="-qt" goto qt
if /I "%~1"=="-dashboard" goto dashboard
if /I "%~1"=="-reset" goto reset
if /I "%~1"=="-uninstall" goto uninstall
if /I "%~1"=="-ver" goto ver
if /I "%~1"=="-help" goto help
if "%~1"=="" goto help

echo [!] Error: Unknown command '%~1'
echo.
goto help

:qt
schtasks /run /tn "AutoDM - Quick Toggle" >nul 2>&1
exit /b

:dashboard
call "C:\Program Files\Detaroxz\AutoDM\AutoDM-Dashboard.cmd"
exit /b

:reset
echo Resetting AutoDM Scheduled Tasks...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Unregister-ScheduledTask -TaskName 'AutoDM - Light Mode' -Confirm:$false -ErrorAction SilentlyContinue; Unregister-ScheduledTask -TaskName 'AutoDM - Dark Mode' -Confirm:$false -ErrorAction SilentlyContinue; Unregister-ScheduledTask -TaskName 'AutoDM - Boot Sync' -Confirm:$false -ErrorAction SilentlyContinue; Unregister-ScheduledTask -TaskName 'AutoDM - Quick Toggle' -Confirm:$false -ErrorAction SilentlyContinue; $p=New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest; $s=New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 1) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable; $aSync=New-ScheduledTaskAction -Execute 'wscript.exe' -Argument '\"C:\Program Files\Detaroxz\AutoDM\Engine\RunSilent.vbs\" \"C:\Program Files\Detaroxz\AutoDM\Engine\SyncTheme.cmd\"'; $aToggle=New-ScheduledTaskAction -Execute 'wscript.exe' -Argument '\"C:\Program Files\Detaroxz\AutoDM\Engine\RunSilent.vbs\" \"C:\Program Files\Detaroxz\AutoDM\Engine\ToggleTheme.cmd\"'; Register-ScheduledTask -TaskName 'AutoDM - Light Mode' -Action $aSync -Principal $p -Trigger (New-ScheduledTaskTrigger -Daily -At '07:00') -Settings $s -Force | Out-Null; Register-ScheduledTask -TaskName 'AutoDM - Dark Mode' -Action $aSync -Principal $p -Trigger (New-ScheduledTaskTrigger -Daily -At '19:00') -Settings $s -Force | Out-Null; Register-ScheduledTask -TaskName 'AutoDM - Boot Sync' -Action $aSync -Principal $p -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Settings $s -Force | Out-Null; $xmlBoot = (Export-ScheduledTask -TaskName 'AutoDM - Boot Sync') -replace '</Triggers>', '<SessionStateChangeTrigger><StateChange>SessionUnlock</StateChange></SessionStateChangeTrigger></Triggers>'; Register-ScheduledTask -TaskName 'AutoDM - Boot Sync' -Xml $xmlBoot -Force | Out-Null; Register-ScheduledTask -TaskName 'AutoDM - Quick Toggle' -Action $aToggle -Principal $p -Settings $s -Force | Out-Null; Write-Host 'Tasks successfully reset to defaults (07:00 / 19:00).' -ForegroundColor Green"
exit /b

:uninstall
start "" "C:\Program Files\Detaroxz\AutoDM\Uninstall.cmd"
exit /b

:ver
echo AutoDM v1.3.1
exit /b

:help
echo ========================================
echo   AutoDM v1.3.1 by detaroxz
echo ========================================
echo.
echo Usage: autodm [command]
echo.
echo Commands:
echo   -qt        : Instantly toggles the current theme (Light/Dark)
echo   -dashboard : Opens the AutoDM Dashboard
echo   -reset     : Deletes and re-creates the Task Scheduler tasks
echo   -uninstall : Uninstalls AutoDM from your system
echo   -ver       : Displays the current AutoDM version
echo   -help      : Displays this help menu
echo.
exit /b
