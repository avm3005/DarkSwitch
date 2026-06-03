@echo off
:: Runs the Core directly in the current window
set "CORE_PATH=%~dp0AutoDM-Core.cmd"
set "C=iex (Get-Content -LiteralPath '%CORE_PATH%' -Raw)"
net session >nul 2>&1 || (powershell -NoProfile -WindowStyle Hidden -Command "Start-Process cmd -ArgumentList '/c \"\"%CORE_PATH%\"\"' -Verb RunAs" & exit /b)
if not defined WT_SESSION (
    where wt >nul 2>&1 && (wt powershell -NoProfile -ExecutionPolicy Bypass -Command "%C%" 2>nul & exit /b)
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "%C%"
exit /b
