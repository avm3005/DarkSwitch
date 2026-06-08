Set WshShell = CreateObject("WScript.Shell")
args = ""
For i = 0 to WScript.Arguments.Count - 1
    args = args & """" & WScript.Arguments(i) & """ "
Next
WshShell.Run "cmd.exe /c """ & args & """", 0, False
