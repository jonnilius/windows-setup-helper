using namespace System.Windows.Forms
using namespace System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

<## PSConsole #########################################################################>
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

<# WINDOW #########################################################################>
function Show-Window {
    param ( $Control )
    if (-not $Control) { return }

    $Form = if ($Control -ne [System.Windows.Forms.Form]) { $Control.FindForm() } else { $Control }
    if (-not $Form.Visible) { $Form.Visible = $true }
}
function Hide-Window {
    param ( $Control )
    if (-not $Control) { return }

    $Form = if ($Control -ne [System.Windows.Forms.Form]) { $Control.FindForm() } else { $Control }
    if ($Form.Visible) { $Form.Visible = $false }
}

<# DOWNLOADER #########################################################################>
function Get-Downloader {
    <#
    .SYNOPSIS
        Erstellt ein WebClient-Objekt mit Proxy-Unterstützung.

    .DESCRIPTION
        Diese Funktion erzeugt ein vorkonfiguriertes .NET-WebClient-Objekt, das
        Proxy-Einstellungen und Anmeldeinformationen aus der Systemumgebung übernimmt.
        Sie dient als Grundlage für Datei-Downloads über HTTP/HTTPS.

    .PARAMETER Url
        Optionale Ziel-URL, um zu prüfen, ob der Proxy den Zugriff umgehen sollte.

    .PARAMETER ProxyUrl
        Optionaler Proxyserver (z.B. "http://proxy.firma.local:8080").

    .PARAMETER ProxyCredential
        Anmeldeinformationen für den Proxy (vom Typ [PSCredential]).

    .OUTPUTS
        Gibt ein konfiguriertes [System.Net.WebClient]-Objekt zurück.

    .EXAMPLE
        $downloader = Get-Downloader -Url "https://example.com/datei.zip"
        $download.DownloadFile("https://example.com/datei.zip", "C:\temp\datei.zip")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)][string] $Url,
        [Parameter(Mandatory = $false)][string] $ProxyUrl,
        [Parameter(Mandatory = $false)][System.Management.Automation.PSCredential] $ProxyCredential
    )

    $downloader = New-Object System.Net.WebClient

    $defaultCreds = [System.Net.CredentialCache]::DefaultCredentials
    if ($defaultCreds) { $downloader.Credentials = $defaultCreds }

    if ($ProxyUrl) {
        Write-Host "Verwendung des übergebenen Proxy-Servers '$ProxyUrl'."
        $proxy = New-Object System.Net.WebProxy -ArgumentList $ProxyUrl, $true

        $proxy.Credentials = if ($ProxyCredential) {
            $ProxyCredential.GetNetworkCredential()
        } elseif ($defaultCreds) {
            $defaultCreds
        } else {
            Write-Warning "Keine Proxy-Anmeldedaten gefunden - manuelle Eingabe erforderlich."
            (Get-Credential).GetNetworkCredential()
        }

        if (-not $proxy.IsBypassed($Url)) {
            $downloader.Proxy = $proxy
        }
    } 

    return $downloader
}
function Request-File {
    <#
    .SYNOPSIS
        Lädt eine Datei von einer URL herunter.

    .DESCRIPTION
        Lädt eine Datei über HTTP oder HTTPS von der angegebenen Quelle herunter.
        Unterstützt optionale Proxy-Konfigurationen und Fehlerbehandlung.

    .PARAMETER Url
        Die vollständige Download-URL der Datei.

    .PARAMETER File
        Der lokale Speicherpfad, unter dem die Datei gespeichert werden soll.

    .PARAMETER ProxyConfiguration
        Optionales Hashtable mit Proxy-Parametern (ProxyUrl, ProxyCredential).

    .EXAMPLE
        Request-File -Url "https://example.com/file.zip" -File "C:\Temp\file.zip"

    .NOTES
        Diese Funktion nutzt Get-Downloader zur automatischen Proxy-Erkennung.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)][string] $Url,
        [Parameter(Mandatory = $false)][string] $File,
        [Parameter(Mandatory = $false)][hashtable] $ProxyConfiguration
    )

    $dl = Get-Downloader -Url $Url @ProxyConfiguration
    try { $dl.DownloadFile($Url, $File) }
    catch { throw "Download fehlgeschlagen: $_" }
}

<# MESSAGE BOX #########################################################################>
function Show-MessageBox {
    param (
        [string]$Config,
        [string]$Message,
        [string]$Title = "Information",
        [string]$Icon = "Info",
        [string]$Buttons = "OK"
    )

    # Konfigurationen für verschiedene Szenarien
    switch($Config){
        # WinGet
        "ConfirmUninstallWinGet" {
            $Text = "Möchten Sie WinGet wirklich deinstallieren?"
            $Caption = "WinGet Deinstallation bestätigen"
            $Icon = "Question"
            $Buttons = "YesNo"
        }
        "UninstallWinGetSuccess" {
            $Text = "WinGet wurde erfolgreich deinstalliert."
            $Caption = "Deinstallation erfolgreich"
            $Icon = "Info"
            $Buttons = "OK"
        }
        "UninstallWinGetFailed" {
            $Text = "Die Deinstallation von WinGet ist fehlgeschlagen."
            $Caption = "Deinstallation fehlgeschlagen"
            $Icon = "Error"
            $Buttons = "OK"
        }
        "InstallWinGetSuccess" {
            $Text = "WinGet wurde erfolgreich installiert."
            $Caption = "Installation erfolgreich"
            $Icon = "Info"
            $Buttons = "OK"
        }
        "InstallWinGetFailed" {
            $Text = "Die Installation von WinGet ist fehlgeschlagen."
            $Caption = "Installation fehlgeschlagen"
            $Icon = "Error"
            $Buttons = "OK"
        }

        # Chocolatey
        "ConfirmUninstallChocolatey" {
            $Text       = "Möchten Sie Chocolatey wirklich deinstallieren?"
            $Caption    = "Chocolatey Deinstallation bestätigen"
            $Icon       = "Question"
            $Buttons    = "YesNo"
        }
        "UninstallChocolateySuccess" {
            $Text = "Chocolatey wurde erfolgreich deinstalliert."
            $Caption = "Deinstallation erfolgreich"
            $Icon = "Info"
            $Buttons = "OK"
        }
        "UninstallChocolateyFailed" {
            $Text = "Die Deinstallation von Chocolatey ist fehlgeschlagen."
            $Caption = "Deinstallation fehlgeschlagen"
            $Icon = "Error"
            $Buttons = "OK"
        }
        "InstallChocolateySuccess" {
            $Text = "Chocolatey wurde erfolgreich installiert."
            $Caption = "Installation erfolgreich"
            $Icon = "Info"
            $Buttons = "OK"
        }
        "InstallChocolateyFailed" {
            $Text = "Die Installation von Chocolatey ist fehlgeschlagen."
            $Caption = "Installation fehlgeschlagen"
            $Icon = "Error"
            $Buttons = "OK"
        }

        # Packages
        "UninstallPackagesConfirm" {
            $Text = "Möchten Sie die ausgewählten Pakete wirklich deinstallieren?"
            $Caption = "Paketdeinstallation bestätigen"
            $Icon = "Warning"
            $Buttons = "YesNo"
        }
        "UninstallPackagesFinished" {
            $Text = "Die Deinstallation der ausgewählten Pakete ist abgeschlossen."
            $Caption = "Deinstallation abgeschlossen"
            $Icon = "Info"
            $Buttons = "OK"
        }
        "UninstallPackageFailed" {
            $Text = "Die Deinstallation des ausgewählten Pakets ist fehlgeschlagen."
            $Caption = "Deinstallation fehlgeschlagen"
            $Icon = "Error"
            $Buttons = "OK"
        }
        "UpdatePackagesSuccess" {
            $Text = "Die ausgewählten Pakete wurden erfolgreich aktualisiert."
            $Caption = "Aktualisierung erfolgreich"
            $Icon = "Info"
            $Buttons = "OK"
        }
        "UpdatePackagesFailed" {
            $Text = "Die Aktualisierung der ausgewählten Pakete ist fehlgeschlagen."
            $Caption = "Aktualisierung fehlgeschlagen"
            $Icon = "Error"
            $Buttons = "OK"
        }
        "InstallPackagesSuccess" {
            $Text = "Die ausgewählten Pakete wurden erfolgreich installiert."
            $Caption = "Installation erfolgreich"
            $Icon = "Info"
            $Buttons = "OK"
        }
        "InstallPackagesFailed" {
            $Text = "Die Installation der ausgewählten Pakete ist fehlgeschlagen."
            $Caption = "Installation fehlgeschlagen"
            $Icon = "Error"
            $Buttons = "OK"
        }

        # Paket 
        "ErrorUpdatingPackage" {
            $Text = "Fehler beim Aktualisieren des Pakets. Bitte überprüfen Sie die Protokolle für weitere Details."
            $Caption = "Paketaktualisierung fehlgeschlagen"
            $Icon = "Error"
            $Buttons = "OK"
        }
        "ComingSoon" {
            $Text = "Diese Funktion ist noch in Arbeit. Bitte haben Sie etwas Geduld."
            $Caption = "In Kürze verfügbar"
            $Icon = "Info"
            $Buttons = "OK"
        }
         default {
            $Text    = if ($Message) { $Message } else { "Unbekannte Konfiguration: $Config" }
            $Caption = if ($Title) { $Title } else { "Fehler" }
            $Icon    = if ($Icon) { $Icon } else { "Error" }
            $Buttons = if ($Buttons) { $Buttons } else { "OK" }
        }
    }

    # Icon validieren
    $iconEnum = switch ($Icon.ToLower()) {
        "info"      { [System.Windows.Forms.MessageBoxIcon]::Information }
        "warning"   { [System.Windows.Forms.MessageBoxIcon]::Warning }
        "question"  { [System.Windows.Forms.MessageBoxIcon]::Question }
        "error"     { [System.Windows.Forms.MessageBoxIcon]::Error }
        default     { [System.Windows.Forms.MessageBoxIcon]::None }
    }

    # Buttons validieren
    $buttonsEnum = switch ($Buttons.ToUpper()) {
        "OK"        { [System.Windows.Forms.MessageBoxButtons]::OK }
        "OKCANCEL"  { [System.Windows.Forms.MessageBoxButtons]::OKCancel }
        "YESNO"     { [System.Windows.Forms.MessageBoxButtons]::YesNo }
        default     { [System.Windows.Forms.MessageBoxButtons]::OK }
    }

    # MessageBox anzeigen und Ergebnis zurückgeben
    $result = [System.Windows.Forms.MessageBox]::Show($Text, $Caption, $buttonsEnum, $iconEnum)
    switch ($buttonsEnum) {
        [System.Windows.Forms.MessageBoxButtons]::YesNo     { return $result -eq [System.Windows.Forms.DialogResult]::Yes }
        [System.Windows.Forms.MessageBoxButtons]::OKCancel  { return $result -eq [System.Windows.Forms.DialogResult]::OK }
        [System.Windows.Forms.MessageBoxButtons]::OK        { return $result -eq [System.Windows.Forms.DialogResult]::OK }
        default { return $result }
    }
}

<# SHELL PROCESS #>
function Start-ShellProcess {
    <# 
    .SYNOPSIS
        Erstellt ein Process-Objekt mit den angegebenen Parametern.
    .PARAMETER FileName
        Der Name oder Pfad der ausführbaren Datei oder des Skripts, das gestartet werden soll.
    .PARAMETER Arguments
        Zusätzliche Argumente oder Parameter, die an die ausführbare Datei oder das Skript übergeben werden sollen.
    .EXAMPLE
        $process = Start-ShellProcess -FileName "notepad.exe" -Arguments "C:\example.txt"
    #>
    param( [string]$FileName, [string]$Arguments = "" )
    
    # Erstelle ein neues ProcessStartInfo-Objekt mit den angegebenen Parametern und konfiguriere es für die Ausführung eines Shell-Befehls.
    $processStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $processStartInfo.FileName                  = $FileName     # Der Name oder Pfad der ausführbaren Datei oder des Skripts, das gestartet werden soll.
    $processStartInfo.Arguments                 = $Arguments    # Zusätzliche Argumente oder Parameter, die an die ausführbare Datei oder das Skript übergeben werden sollen.
    $processStartInfo.UseShellExecute           = $false        # Shell-Execute deaktivieren, um die Standardausgabe umzuleiten
    $processStartInfo.CreateNoWindow            = $true         # Kein neues Fenster erstellen (nützlich für Konsolenanwendungen)
    $processStartInfo.RedirectStandardOutput    = $true         # Standardausgabe umleiten, damit sie im Hauptprozess gelesen werden kann
    $processStartInfo.RedirectStandardError     = $true         # Standardfehler umleiten, damit sie im Hauptprozess gelesen werden kann

    # Starte den Prozess mit den konfigurierten Einstellungen
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $processStartInfo
    $process.Start() | Out-Null 

    # Gebe das Process-Objekt zurück
    return $process
}
function Stop-ShellProcess {
    param ( [System.Diagnostics.Process]$Process )
    if ($Process -and -not $Process.HasExited) {
        $Process.Kill()
        $Process.WaitForExit(500) | Out-Null  # Warte bis zu 500ms, um sicherzustellen, dass der Prozess vollständig beendet ist
    }
}

<# ADMINISTRATOR CHECK #>
function Get-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

<# FILL CHECK #>
function Test-Fill {
    param ( $Value )
    if ($null -eq $Value) { return $false }

    
    if ($Value -is [string]) { return -not [string]::IsNullOrWhiteSpace($Value) }
    if ($Value -is [System.Collections.IEnumerable]) { 
        foreach ($item in $Value) { return $true }
        return $false 
    }
    
    return $true
}
function Test-Empty {
    param ( $Value )
    
    return [string]::IsNullOrWhiteSpace([string]$Value)
}


function Set-Timer {
    param( $Context, [scriptblock]$Action, [int]$Interval = 150 )


    $timer = [Timer]::new()
    $timer.Tag      = $Context
    $timer.Interval = $Interval
    $timer.Add_Tick($Action)
    return $timer
}
<# TIMER #>
function Start-Timer {
    param ( [Timer]$Timer, [string]$Name = "Timer", [System.Windows.Forms.Control]$Control )

    # Erstelle einen Timer mit dem angegebenen Intervall
    if ($Timer -isnot [Timer]) { return }
    if (Test-Control $Control) { 
        if ($Control.Tag -isnot [hashtable]) { $Control.Tag = @{} }
        $Control.Tag[$Name] = $Timer
    }
    
    $Timer.Start()

}

function Stop-Timer {
    param( 
        [System.Windows.Forms.Control]$Control, 
        [Alias("Name")][string]$TimerName, 
        [Timer]$Timer 
        )
    Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name) | Params: Control='$($Control.Name)', TimerName='$TimerName'"

    # Wenn ein Steuerelement übergeben wird, versuchen, das zugehörige Timer-Objekt aus dem Tag des Steuerelements abzurufen
    if (Test-Control $Control) { 
        # Sicherstellen, dass das Steuerelement über die erwarteten Tag-Strukturen verfügt, um Fehler zu vermeiden
        if (-not ($Control.Tag -is [hashtable])) { return }

        # Timer-Objekt aus dem Tag des Steuerelements abrufen
        if ( $TimerName -and $Control.Tag.ContainsKey($TimerName)) { $Timer = $Control.Tag[$TimerName] }
        else { 
            # Kein TimerName = explizit ALLE Timer stoppen
            # Achtung: wir iterieren über eine Kopie (@(...)), weil wir währenddessen Einträge entfernen
            foreach ($key in @($Control.Tag.Keys)) {
                if ($Control.Tag[$key] -is [Timer]) { 
                    # Stoppen und Bereinigen des Timer-Objekts
                    Stop-Timer -Control $Control -TimerName $key
                }
            }
            return
        }
    } 

    # Sicherstellen, dass das übergebene Objekt tatsächlich ein Timer ist, um Fehler zu vermeiden
    if (-not ($Timer -is [Timer])) { return }
    
    # WICHTIG: Dispose ist nötig, damit der Timer nicht im Hintergrund weiterlebt
    # und Referenzen hält (sonst Memory-Leaks / Ghost-Ticks möglich)
    $Timer.Stop()
    $Timer.Dispose()   
    
    # Timer-Objekt aus dem Tag des Steuerelements entfernen
    if ($Control -and $TimerName) { $Control.Tag.Remove($TimerName) }
}
##############################################################################################################
function Start-Command {
    param ( [string]$Command, [switch]$RunAsAdmin )
    if ($RunAsAdmin) {
        return Start-Process powershell -ArgumentList "-Command $Command" -Verb RunAs 
    } else {
        Write-Host "Starte Befehl: $Command"
        return Start-Process powershell -ArgumentList "-Command $Command" -NoNewWindow -Wait
    }
}

