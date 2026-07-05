param([string]$Action = 'SYNC')
$regDM = "HKCU:\SOFTWARE\DarkSwitch"
$regData = Get-ItemProperty $regDM -ErrorAction SilentlyContinue
if (-not $regData) { exit }

$dllPath = "C:\Program Files\Detaroxz\DarkSwitch\Engine\DarkSwitchEngine.dll"
if (Test-Path $dllPath) { [Reflection.Assembly]::LoadFile($dllPath) | Out-Null }

$now = [datetime]::Now
$dynSun = ($regData.DynamicSun -eq 'Y')

if ($Action -eq 'SUN' -or ($Action -eq 'BOOT' -and $dynSun)) {
    if ($dynSun -and $regData.LastLat -and $regData.LastLon) {
        $latStr = $regData.LastLat.ToString()
        $lonStr = $regData.LastLon.ToString()
        $lat = [double]::Parse($latStr.Replace(',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
        $lon = [double]::Parse($lonStr.Replace(',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
        $times = [DarkSwitch.SunCalc]::GetSunTimes($lat, $lon, $now)
        
        if ($times[0] -ne [datetime]::MinValue) {
            $tPath = "\Detaroxz\DarkSwitch\"
            try {
                $tL = Get-ScheduledTask -TaskName "DarkSwitch - Light Mode" -TaskPath $tPath -ErrorAction Stop
                $tL.Triggers[0].StartBoundary = $times[0].ToString("yyyy-MM-ddTHH:mm:ss")
                $tL | Set-ScheduledTask -User $env:USERNAME -ErrorAction Stop | Out-Null
            } catch {}
            try {
                $tD = Get-ScheduledTask -TaskName "DarkSwitch - Dark Mode" -TaskPath $tPath -ErrorAction Stop
                $tD.Triggers[0].StartBoundary = $times[1].ToString("yyyy-MM-ddTHH:mm:ss")
                $tD | Set-ScheduledTask -User $env:USERNAME -ErrorAction Stop | Out-Null
            } catch {}
        }
    }
}

$isLight = $false

if ($Action -eq 'SYNC_LIGHT') {
    $isLight = $true
    Set-ItemProperty $regDM -Name "OverrideTime" -Value 0 -Type QWord -Force -ErrorAction SilentlyContinue
} elseif ($Action -eq 'SYNC_DARK') {
    $isLight = $false
    Set-ItemProperty $regDM -Name "OverrideTime" -Value 0 -Type QWord -Force -ErrorAction SilentlyContinue
} else {
    $tLight = Get-ScheduledTask -TaskPath "\Detaroxz\DarkSwitch\" -TaskName "DarkSwitch - Light Mode" -ErrorAction SilentlyContinue
    $tDark = Get-ScheduledTask -TaskPath "\Detaroxz\DarkSwitch\" -TaskName "DarkSwitch - Dark Mode" -ErrorAction SilentlyContinue
    if ($tLight -and $tDark -and $tLight.State -ne 'Disabled') {
        $lTime = [datetime]($tLight.Triggers[0].StartBoundary)
        $dTime = [datetime]($tDark.Triggers[0].StartBoundary)
        $todayL = $now.Date + $lTime.TimeOfDay
        $todayD = $now.Date + $dTime.TimeOfDay
        $pastL = if ($now -ge $todayL) { $todayL } else { $todayL.AddDays(-1) }
        $pastD = if ($now -ge $todayD) { $todayD } else { $todayD.AddDays(-1) }
        $recentB = if ($pastL -gt $pastD) { $pastL } else { $pastD }
        
        if ($Action -eq 'SYNC') { Set-ItemProperty $regDM -Name "OverrideTime" -Value 0 -Type QWord -Force -ErrorAction SilentlyContinue }
        $overrideTicks = (Get-ItemProperty $regDM -Name "OverrideTime" -ErrorAction SilentlyContinue).OverrideTime
        if ($overrideTicks -and [long]$overrideTicks -gt $recentB.Ticks) { exit }
        
        $isLight = ($recentB -eq $pastL)
    } else { exit }
}

$newVal = if ($isLight) { 1 } else { 0 }
$regTheme = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$currApp = (Get-ItemProperty -Path $regTheme -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme

if ($currApp -ne $newVal -or $Action -eq 'BOOT') {
    $wpEnBool = ($regData.WallpaperEnabled -eq 1)
    $wpMode = 0; $wpFile = ""; $wpColor = ""; $wpFolder = ""; $wpTick = 600000
    if ($wpEnBool) {
        $wpMode = if ($newVal -eq 1) { $regData.LightWpMode } else { $regData.DarkWpMode }
        $wpFile = if ($newVal -eq 1) { $regData.LightWpFile } else { $regData.DarkWpFile }
        $wpColor = if ($newVal -eq 1) { $regData.LightWpColor } else { $regData.DarkWpColor }
        $wpFolder = if ($newVal -eq 1) { $regData.LightWpFolder } else { $regData.DarkWpFolder }
        $wpTick = if ($newVal -eq 1) { $regData.LightWpInterval } else { $regData.DarkWpInterval }
    }
    $acc = ""
    if ($regData.AccentEnabled -eq 1) { $acc = if ($newVal -eq 1) { $regData.LightAccent } else { $regData.DarkAccent } }
    
    $cur = ""
    if ($regData.CursorEnabled -eq 1) { $cur = if ($newVal -eq 1) { $regData.LightCursor } else { $regData.DarkCursor } }
    
    [DarkSwitch.Engine]::Execute($newVal, $wpEnBool, [int]$wpMode, "$wpFile", "$wpColor", "$wpFolder", [int]$wpTick, "$acc", "$cur")
}
exit
