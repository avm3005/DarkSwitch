Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -Command ""[Reflection.Assembly]::LoadFile('C:\Program Files\Detaroxz\AutoDM\Engine\AutoDMEngine.dll') | Out-Null; [AutoDM.Engine]::Toggle()""", 0, False
