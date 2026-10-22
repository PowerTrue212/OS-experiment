param([string]$OutputPath = "$PSScriptRoot/../T4_best_fit_test_result.png")
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class T4Window {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder text, int n);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out Rect r);
}
'@
$script:t4Handle = [IntPtr]::Zero
$callback = [T4Window+EnumProc]{ param($handle, $unused)
    $title = New-Object System.Text.StringBuilder 512
    [void][T4Window]::GetWindowText($handle, $title, $title.Capacity)
    if ([T4Window]::IsWindowVisible($handle) -and $title.ToString() -like '*T4 Best-Fit*') {
        $script:t4Handle = $handle
        return $false
    }
    return $true
}
[void][T4Window]::EnumWindows($callback, [IntPtr]::Zero)
if ($script:t4Handle -eq [IntPtr]::Zero) { throw 'The T4 test terminal is not visible.' }
[void][T4Window]::ShowWindow($script:t4Handle, 3)
[void][T4Window]::SetForegroundWindow($script:t4Handle)
Start-Sleep -Milliseconds 700
if ([T4Window]::GetForegroundWindow() -ne $script:t4Handle) {
    $activate = New-Object -ComObject WScript.Shell
    [void]$activate.AppActivate('T4 Best-Fit')
    Start-Sleep -Milliseconds 300
}
if ([T4Window]::GetForegroundWindow() -ne $script:t4Handle) { throw 'Cannot capture: terminal is not foreground.' }
$rect = New-Object T4Window+Rect
[void][T4Window]::GetWindowRect($script:t4Handle, [ref]$rect)
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$left = [Math]::Max($rect.Left, $screen.Left)
$top = [Math]::Max($rect.Top, $screen.Top)
$right = [Math]::Min($rect.Right, $screen.Right)
$bottom = [Math]::Min($rect.Bottom, $screen.Bottom)
$bitmap = New-Object System.Drawing.Bitmap ($right - $left), ($bottom - $top)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
try {
    $graphics.CopyFromScreen($left, $top, 0, 0, $bitmap.Size)
    $bitmap.Save([System.IO.Path]::GetFullPath($OutputPath), [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
    $graphics.Dispose()
    $bitmap.Dispose()
}
Write-Output ([System.IO.Path]::GetFullPath($OutputPath))
