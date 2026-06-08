# 2>NUL & @echo off
# 2>NUL & set "SELF_PATH=%~f0"
# 2>NUL & set "C=iex (Get-Content -LiteralPath '%SELF_PATH%' -Raw)"
# 2>NUL & powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "%C%"
# 2>NUL & exit /b
$csharpCode = @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using Microsoft.Win32;

namespace AutoDM {
    public class SunCalc {
        public static DateTime[] GetSunTimes(double lat, double lon, DateTime date) {
            try {
                int N = date.DayOfYear;
                double lngHour = lon / 15.0;
                double t_rise = N + ((6.0 - lngHour) / 24.0);
                double t_set = N + ((18.0 - lngHour) / 24.0);

                double M_rise = (0.9856 * t_rise) - 3.289;
                double M_set = (0.9856 * t_set) - 3.289;

                double L_rise = (M_rise + (1.916 * Math.Sin(M_rise * Math.PI/180.0)) + (0.020 * Math.Sin(2 * M_rise * Math.PI/180.0)) + 282.634) % 360.0;
                double L_set = (M_set + (1.916 * Math.Sin(M_set * Math.PI/180.0)) + (0.020 * Math.Sin(2 * M_set * Math.PI/180.0)) + 282.634) % 360.0;
                if(L_rise < 0) L_rise += 360.0; if(L_set < 0) L_set += 360.0;

                double RA_rise = (180.0/Math.PI) * Math.Atan(0.91764 * Math.Tan(L_rise * Math.PI/180.0));
                double RA_set = (180.0/Math.PI) * Math.Atan(0.91764 * Math.Tan(L_set * Math.PI/180.0));
                RA_rise = (RA_rise % 360.0); if(RA_rise < 0) RA_rise += 360.0;
                RA_set = (RA_set % 360.0); if(RA_set < 0) RA_set += 360.0;

                double Lquadrant_rise  = (Math.Floor( L_rise/90.0)) * 90.0;
                double RAquadrant_rise = (Math.Floor(RA_rise/90.0)) * 90.0;
                RA_rise = RA_rise + (Lquadrant_rise - RAquadrant_rise);
                RA_rise = RA_rise / 15.0;

                double Lquadrant_set  = (Math.Floor( L_set/90.0)) * 90.0;
                double RAquadrant_set = (Math.Floor(RA_set/90.0)) * 90.0;
                RA_set = RA_set + (Lquadrant_set - RAquadrant_set);
                RA_set = RA_set / 15.0;

                double sinDec_rise = 0.39782 * Math.Sin(L_rise * Math.PI/180.0);
                double cosDec_rise = Math.Cos(Math.Asin(sinDec_rise));
                double sinDec_set = 0.39782 * Math.Sin(L_set * Math.PI/180.0);
                double cosDec_set = Math.Cos(Math.Asin(sinDec_set));

                double cosH_rise = (Math.Cos(90.833 * Math.PI/180.0) - (sinDec_rise * Math.Sin(lat * Math.PI/180.0))) / (cosDec_rise * Math.Cos(lat * Math.PI/180.0));
                double cosH_set = (Math.Cos(90.833 * Math.PI/180.0) - (sinDec_set * Math.Sin(lat * Math.PI/180.0))) / (cosDec_set * Math.Cos(lat * Math.PI/180.0));

                if (cosH_rise > 1 || cosH_rise < -1) return new DateTime[] { DateTime.MinValue, DateTime.MinValue };

                double H_rise = (360.0 - (180.0/Math.PI) * Math.Acos(cosH_rise)) / 15.0;
                double H_set = ((180.0/Math.PI) * Math.Acos(cosH_set)) / 15.0;

                double T_rise = H_rise + RA_rise - (0.06571 * t_rise) - 6.622;
                double T_set = H_set + RA_set - (0.06571 * t_set) - 6.622;

                double UT_rise = (T_rise - lngHour) % 24.0; if(UT_rise < 0) UT_rise += 24.0;
                double UT_set = (T_set - lngHour) % 24.0; if(UT_set < 0) UT_set += 24.0;

                DateTime rise = new DateTime(date.Year, date.Month, date.Day, 0, 0, 0, DateTimeKind.Utc).AddHours(UT_rise).ToLocalTime();
                DateTime set = new DateTime(date.Year, date.Month, date.Day, 0, 0, 0, DateTimeKind.Utc).AddHours(UT_set).ToLocalTime();

                return new DateTime[] { rise, set };
            } catch { return new DateTime[] { DateTime.MinValue, DateTime.MinValue }; }
        }
    }

    public class Engine {
        [DllImport("uxtheme.dll", EntryPoint = "#104")] public static extern void RefreshImmersiveColorPolicyState();
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern bool SendNotifyMessage(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam);
        [ComImport, Guid("C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD")] public class DesktopWallpaper { }
        [ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] public interface IDesktopWallpaper { void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] string wallpaper); }

        public static void RefreshTheme() {
            try { RefreshImmersiveColorPolicyState(); } catch {}
            
            // 1. INSTANT: Queue messages asynchronously on the RealTime thread.
            // This triggers the immediate UI switch across Explorer and wakes suspended UWP apps (Settings).
            SendNotifyMessage((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "ImmersiveColorSet");
            SendNotifyMessage((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "AppsUseLightTheme");
            SendNotifyMessage((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "SystemUsesLightTheme");
            SendNotifyMessage((IntPtr)0xFFFF, 0x031A, IntPtr.Zero, null);

            // 2. BACKGROUND: Synchronous broadcasts block and cause stuttering. We offload these.
            // Ensures heavy apps eventually update without holding up the fast Quick Toggle switch.
            Task.Run(() => {
                IntPtr res;
                SendMessageTimeout((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "ImmersiveColorSet", 2, 1000, out res);
                SendMessageTimeout((IntPtr)0xFFFF, 0x031A, IntPtr.Zero, null, 2, 1000, out res);
                SendMessageTimeout((IntPtr)0xFFFF, 0x001A, IntPtr.Zero, "WindowsThemeElement", 2, 1000, out res);
            });
        }

        public static void ApplyWP(string wp) {
            if (string.IsNullOrEmpty(wp)) return;
            try { ((IDesktopWallpaper)new DesktopWallpaper()).SetWallpaper(null, wp); }
            catch { SystemParametersInfo(20, 0, wp, 3); }
        }

        public static void ApplyAcc(string acc) {
            if (string.IsNullOrEmpty(acc)) return;
            ApplyAccInternal(acc);
            RefreshTheme();
        }

        private static void ApplyAccInternal(string acc) {
            if (acc.ToLower() == "auto") {
                using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { 
                    if (desk != null) { desk.SetValue("AutoColorization", 1, RegistryValueKind.DWord); desk.Flush(); }
                }
            } else {
                using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { 
                    if (desk != null) { desk.SetValue("AutoColorization", 0, RegistryValueKind.DWord); desk.Flush(); }
                }
                try {
                    int color = 0; if(acc.StartsWith("#")) acc = acc.Substring(1);
                    if(acc.Length == 6) {
                        int r = Convert.ToInt32(acc.Substring(0,2), 16); int g = Convert.ToInt32(acc.Substring(2,2), 16); int b = Convert.ToInt32(acc.Substring(4,2), 16);
                        color = (b << 16) | (g << 8) | r;
                    }
                    using (RegistryKey dwm = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\DWM")) {
                        if (dwm != null) {
                            dwm.SetValue("AccentColor", color, RegistryValueKind.DWord);
                            dwm.SetValue("ColorizationColor", color | unchecked((int)0xFF000000), RegistryValueKind.DWord);
                            dwm.Flush();
                        }
                    }
                } catch {}
            }
        }

        public static void RestoreAccent(int autoCol, int accCol) {
            using (RegistryKey desk = Registry.CurrentUser.CreateSubKey(@"Control Panel\Desktop")) { 
                if (desk != null) { desk.SetValue("AutoColorization", autoCol, RegistryValueKind.DWord); desk.Flush(); }
            }
            using (RegistryKey dwm = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\DWM")) { 
                if (dwm != null) {
                    dwm.SetValue("AccentColor", accCol, RegistryValueKind.DWord); 
                    dwm.SetValue("ColorizationColor", accCol | unchecked((int)0xFF000000), RegistryValueKind.DWord);
                    dwm.Flush();
                }
            }
            RefreshTheme();
        }

        public static void Execute(int isLight, string wp, string acc) {
            try {
                Process.GetCurrentProcess().PriorityClass = ProcessPriorityClass.RealTime;
                System.Threading.Thread.CurrentThread.Priority = System.Threading.ThreadPriority.Highest;
            } catch {}

            // Sequential atomic execution eliminates threading overhead and lock contention.
            if (isLight != -1) {
                using (RegistryKey reg = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", true)) {
                    if (reg != null) {
                        reg.SetValue("AppsUseLightTheme", isLight, RegistryValueKind.DWord);
                        reg.SetValue("SystemUsesLightTheme", isLight, RegistryValueKind.DWord);
                        reg.Flush();
                    }
                }
            }

            if (!string.IsNullOrEmpty(acc)) {
                ApplyAccInternal(acc);
            }

            // Fire the theme refresh IMMEDIATELY on this RealTime thread.
            // (The fast non-blocking signals run instantly, while slow ones are backgrounded)
            if (isLight != -1 || !string.IsNullOrEmpty(acc)) {
                RefreshTheme();
            }

            // Wallpaper switching hits the GPU/Disk, keep it in the background
            if (!string.IsNullOrEmpty(wp)) {
                Task.Run(() => ApplyWP(wp));
            }
        }

        public static void Toggle() {
            try {
                try {
                    Process.GetCurrentProcess().PriorityClass = ProcessPriorityClass.RealTime;
                    System.Threading.Thread.CurrentThread.Priority = System.Threading.ThreadPriority.Highest;
                } catch {}

                long ticks = DateTime.Now.Ticks;
                using (RegistryKey regDM = Registry.CurrentUser.CreateSubKey(@"SOFTWARE\AutoDM")) {
                    if (regDM != null) {
                        regDM.SetValue("OverrideTime", ticks, RegistryValueKind.QWord);
                        int newVal = 1;
                        using (RegistryKey regTheme = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize")) {
                            if (regTheme != null) {
                                object val = regTheme.GetValue("AppsUseLightTheme");
                                if (val != null && Convert.ToInt32(val) == 1) newVal = 0;
                            }
                        }
                        string wp = ""; string acc = "";
                        object wpEn = regDM.GetValue("WallpaperEnabled");
                        if (wpEn != null && Convert.ToInt32(wpEn) == 1) {
                            wp = (string)regDM.GetValue(newVal == 1 ? "LightWallpaper" : "DarkWallpaper");
                        }
                        object accEn = regDM.GetValue("AccentEnabled");
                        if (accEn != null && Convert.ToInt32(accEn) == 1) {
                            acc = (string)regDM.GetValue(newVal == 1 ? "LightAccent" : "DarkAccent");
                        }
                        Execute(newVal, wp, acc);
                    }
                }
            } catch {}
        }
    }
}
'@
if (-not ('AutoDM.Engine' -as [type])) { try { Add-Type -TypeDefinition $csharpCode -ErrorAction SilentlyContinue } catch {} }
[AutoDM.Engine]::Toggle()
Start-Sleep -Seconds 2
