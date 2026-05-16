if (-not ("ConsoleWindowNativeMethods" -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class ConsoleWindowNativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindowVisible(IntPtr hWnd);
}
"@
}
function Show-PSConsole {
    $consoleWindow = [ConsoleWindowNativeMethods]::GetConsoleWindow()
    if ($consoleWindow -eq [IntPtr]::Zero) { return }
    [void][ConsoleWindowNativeMethods]::ShowWindow($consoleWindow, 4) # 4 = SW_SHOW without activating
}
function Hide-PSConsole {
    $consoleWindow = [ConsoleWindowNativeMethods]::GetConsoleWindow()
    if ($consoleWindow -eq [IntPtr]::Zero) { return }
    [void][ConsoleWindowNativeMethods]::ShowWindow($consoleWindow, 0) # 0 = SW_HIDE
}
function Get-PSConsole {
    $consoleWindow = [ConsoleWindowNativeMethods]::GetConsoleWindow()
    if ($consoleWindow -eq [IntPtr]::Zero) { return $false }
    return [ConsoleWindowNativeMethods]::IsWindowVisible($consoleWindow)
}