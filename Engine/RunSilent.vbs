Set WshShell = CreateObject("WScript.Shell")
scriptPath = WScript.Arguments(0)
args = ""
For i = 1 to WScript.Arguments.Count - 1
    args = args & " """ & WScript.Arguments(i) & """"
Next
WshShell.Run "powershell.exe -Sta -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & scriptPath & """" & args, 0, False
