@echo off
:: Silent Toggle via Elevated Scheduled Task
schtasks /run /tn "\Detaroxz\AutoDM\AutoDM - Quick Toggle" >nul 2>&1
