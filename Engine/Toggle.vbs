Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -Command ""[Reflection.Assembly]::LoadFile('C:\Program Files\Detaroxz\DarkSwitch\Engine\DarkSwitchEngine.dll') | Out-Null; [DarkSwitch.Engine]::Toggle()""", 0, False
