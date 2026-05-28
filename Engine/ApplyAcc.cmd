# 2>NUL & @echo off
# 2>NUL & set "SELF_PATH=%~f0"
# 2>NUL & powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF_PATH)))"
# 2>NUL & exit /b
$regDM = "HKCU:\SOFTWARE\AutoDM"
$regData = Get-ItemProperty $regDM -ErrorAction SilentlyContinue
if ($regData.AccentEnabled -ne 1) { exit }

$regTheme = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$isLight = (Get-ItemProperty $regTheme -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
if ($null -eq $isLight) { $isLight = 1 }

$accToSet = if ($isLight -eq 1) { $regData.LightAccent } else { $regData.DarkAccent }
if (-not $accToSet) { exit }

$curAuto = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name AutoColorization -ErrorAction SilentlyContinue).AutoColorization
$curAcc = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\DWM' -Name AccentColor -ErrorAction SilentlyContinue).AccentColor

if ($accToSet.ToLower() -eq 'auto') {
    if ($curAuto -eq 1) { exit }
} else {
    try {
        $colorStr = $accToSet
        if ($colorStr.StartsWith("#")) { $colorStr = $colorStr.Substring(1) }
        $r = [Convert]::ToInt32($colorStr.Substring(0,2), 16)
        $g = [Convert]::ToInt32($colorStr.Substring(2,2), 16)
        $b = [Convert]::ToInt32($colorStr.Substring(4,2), 16)
        $targetColor = ($b -shl 16) -bor ($g -shl 8) -bor $r
        if ($curAuto -eq 0 -and $curAcc -eq $targetColor) { exit }
    } catch {}
}

$code = @"
using System; using System.Runtime.InteropServices; using Microsoft.Win32;
public class AccTheme {
    [DllImport("uxtheme.dll", EntryPoint = "#104")] public static extern void RefreshImmersiveColorPolicyState();
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
    public static void Apply(string acc) {
        if (acc.ToLower() == "auto") {
            using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { desk.SetValue("AutoColorization", 1, RegistryValueKind.DWord); }
        } else {
            using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { desk.SetValue("AutoColorization", 0, RegistryValueKind.DWord); }
            try {
                int color = 0; if(acc.StartsWith("#")) acc = acc.Substring(1);
                if(acc.Length == 6) {
                    int r = Convert.ToInt32(acc.Substring(0,2), 16); int g = Convert.ToInt32(acc.Substring(2,2), 16); int b = Convert.ToInt32(acc.Substring(4,2), 16);
                    color = (b << 16) | (g << 8) | r;
                }
                using (RegistryKey dwm = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\DWM")) {
                    dwm.SetValue("AccentColor", color, RegistryValueKind.DWord);
                    dwm.SetValue("ColorizationColor", color | unchecked((int)0xFF000000), RegistryValueKind.DWord);
                }
            } catch {}
        }
        try { RefreshImmersiveColorPolicyState(); } catch {}
        IntPtr res; SendMessageTimeout((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "ImmersiveColorSet", 2, 100, out res);
    }
}
"@
if (-not ("AccTheme" -as [type])) { Add-Type -TypeDefinition $code }
[AccTheme]::Apply($accToSet)
exit
