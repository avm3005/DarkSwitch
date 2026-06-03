Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "cmd.exe /c """ & WScript.Arguments(0) & """", 0, False
