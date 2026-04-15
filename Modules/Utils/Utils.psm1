using namespace System.Windows.Forms
using namespace System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Get-PSCallStack
Write-Debug "[INIT] Importiere Utils-Modul: $($MyInvocation.MyCommand.Name) | Version: $($MyInvocation.MyCommand.Version) | Pfad: $($MyInvocation.MyCommand.Path)"

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
    param ( [System.Windows.Forms.Form]$Form )
    if ($Form -and -not $Form.Visible) { $Form.Visible = $true }
}
function Hide-Window {
    param ( [System.Windows.Forms.Form]$Form )
    if ($Form -and $Form.Visible) { $Form.Visible = $false }
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

function Get-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-DeviceName {
    param ( [string]$NewName )
    if ($NewName -eq $null -or $NewName.Trim() -eq "") {
        Show-MessageBox -Message "Der Gerätename wurde nicht geändert!" -Title "Fehler" -Buttons "OK" -Icon "Error"
    }
    else {
        Rename-Computer -NewName $NewName -Force
        $restart = Show-MessageBox -Message "Der Gerätename wurde erfolgreich geändert! `nStarten Sie den Computer neu, um die Änderungen zu übernehmen.`nMöchten Sie den Computer jetzt neu starten?" -Title "Erfolg" -Buttons "YesNo" -Icon "Question"
        if ($restart) {
            Restart-Computer -Force
        } else {
            Show-MessageBox -Message "Der Computer muss neu gestartet werden, damit die Änderung wirksam wird!" -Title "Neustart erforderlich" -Buttons "OK" -Icon "Warning"
        }
    }
}

function Watch-Empty {
    param ( $Value )
    
    if ($null -eq $Value) { return $true }
    if ($Value -is [string]) { return [string]::IsNullOrWhiteSpace($Value) }
    else { return $false }
}
function Test-Fill {
    param ( $Value )

    if ($null -eq $Value) { return $false }
    
    if ($Value -is [string]) { return -not [string]::IsNullOrWhiteSpace($Value) }
    if ($Value -is [System.Collections.IEnumerable]) { return $Value.Count -gt 0 }
    
    return $true
}
function Test-String {
    param ( $Value )
    
    if ($Value -is [string]) { return [string]::IsNullOrWhiteSpace($Value) }
    else { return $false }
}

function Update-ProcessLabel {
    param( 
        $Control,           # $this-Objekt, um auf die Steuerelemente zuzugreifen
        [string]$Message,   # Die Nachricht, die im Label angezeigt werden soll
        [int]$Delay = 0,    # Optionale Verzögerung in Sekunden, bevor die Nachricht aktualisiert wird
        [switch]$Final      # Optionaler Schalter, der angibt, ob dies die letzte Aktualisierung ist (z. B. nach Abschluss eines Prozesses)
    )
    Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name) | Params: $($PSBoundParameters | Out-String)"

    if (-not $Control) { throw "Der Parameter 'Control' ist erforderlich, um auf die Steuerelemente zuzugreifen." }
    $label = (Get-Control $Control "ProcessLabel")

    # Überprüfen, ob der Aufruf von einem anderen Thread stammt, und gegebenenfalls den Aufruf auf den UI-Thread verschieben.
    Write-Debug "Prüfe, ob der Aufruf von einem anderen Thread stammt: InvokeRequired = $($label.InvokeRequired)"
    if ($label.InvokeRequired) {
        $label.Invoke({ 
            param($l, $m, $d, $f) 
            Update-ProcessLabel -Control $l -Message $m -Delay $d -Final:$f 
        }, $Control, $Message, $Delay, $Final)
        return
    }
    
    # Aktualisiert den Text des Labels mit der übergebenen Nachricht und erzwingt die Aktualisierung der Benutzeroberfläche.
    $label.Text = $Message
    Write-Debug "Aktualisiere Label-Text: $Message"
    [Application]::DoEvents()
    
    # Stellt sicher, dass das Label sichtbar wird, wenn der Status aktualisiert wird.
    if ($label.Visible -eq $false) {
        Write-Debug "Ändere Sichtbarkeit des Labels auf sichtbar, da es derzeit ausgeblendet ist."
        $label.Visible = $true 
        Set-Cursor "Wait"
    }

    # Delay falls angegeben
    Start-Sleep -Seconds $Delay

    # Wenn der Final-Parameter gesetzt ist, wird das Label nach einer kurzen Verzögerung ausgeblendet.
    if ($Final) {
        Write-Debug "Final-Parameter ist gesetzt. Blende Label nach $Delay Sekunden aus."
        $FinalAction = {
            $this.Stop()
            $this.Dispose()
            Set-Cursor "Default"
            $this.Tag.Label.Visible = $false
        }
        Start-Timer -Interval ($Delay * 1000) -Action $FinalAction -State @{ Label = $label }
    }
    return
}

function Start-Timer {
    param ( [int]$Interval, [scriptblock]$Action, [hashtable]$State = $null )
    Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name) | Params: $($PSBoundParameters | Out-String)"

    if (-not $Action) { throw "Der Parameter 'Action' ist erforderlich, um die Aktion zu definieren, die beim Tick des Timers ausgeführt werden soll." }

    # Erstelle einen Timer mit dem angegebenen Intervall
    $timer = [Timer]::new()
    $timer.Interval = $Interval

    # Wenn ein Status übergeben wurde, speichere ihn im Tag des Timers, damit er im Action-Skript verfügbar ist
    if ($State) { $timer.Tag = $State }

    $timer.Add_Tick($Action)
    $timer.Start()
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

function Remove-StartMenuIcons {
    param ( $take )
    & $AppLog.Info "Funktion 'Remove-StartMenuIcons' aufgerufen."

    # Führe das Skript zum Entfernen der Startmenü-Icons aus
    $RootPath = $AppInfo.Path
    & "$RootPath\Debloat\Remove-StartMenuIcons.ps1" $take
}



<# WINGET #>
function Get-WinGet {
    param ( 
        [scriptblock]$ShowText = { 
            param($msg, [switch]$Final) 
            Write-Host $msg
            if ($Final) { Start-Sleep -Seconds 2 } 
        },

        $App,
        [string]$AppName,
        [string]$AppId,
        
        [PSCustomObject[]]$AppsUpdateAvailable,
        [object[]]$UninstallApps,
        $InstallApps,
        [System.Windows.Forms.ListBox]$ListBoxApps,
        
        
        [switch]$Install,
        [switch]$Installed,
        [switch]$List,
        [switch]$SetupList,
        [switch]$Uninstall,
        [switch]$Update,
        $UpdateApps,
        [switch]$UpdateAvailable,
        [switch]$Version
    )

    # WinGet-Installation, -Deinstallation, -Version, -Liste, -Updates
    if ($AppVersion) {
        $AppId = if ($App.Id) { $App.Id } else { throw "Keine gültige App-Id für die Versionsermittlung vorhanden." }
        $ver = winget show --id=$AppId --source=winget | Where-Object { $_ -match "^Version:" } | ForEach-Object { ($_ -split ":")[1].Trim() }
        return $ver
    } elseif ($AppsUpdateAvailable) {
        $IsUpdateAvailable = $false
        foreach ($app in $Apps) {
            $Id = $app.Id
            $Version = winget show --id=$($app.Id) --source=winget | Where-Object { $_ -match "^Version:" } | ForEach-Object { ($_ -split ":")[1].Trim() }
            $WinGetPackage = Get-WinGetPackage -Id $Id -Source "winget" -ErrorAction SilentlyContinue

            if ($WinGetPackage -and $WinGetPackage.IsUpdateAvailable) {
                & $ShowText "Update verfügbar für $($app.Name) (Version: $Version)"
                $IsUpdateAvailable = $true
            } else {
                & $ShowText "$($app.Name) ist auf dem neuesten Stand."
            }
        }
        return $IsUpdateAvailable
    } elseif ($Install) {
        if ($Apps -and $Apps.Count -gt 0) {
            foreach ($currentApp in $Apps) {
                & $ShowText "Installiere $($currentApp.Name)..."
                $ok = & $InstallWithMsStore -Id $currentApp.Id -Name $currentApp.Name
                if (-not $ok) { & $ShowText "Fehler: $($currentApp.Name) konnte nicht installiert werden." }
            }
            & $ShowText "Alle ausgewählten Apps wurden installiert." -Final
            return
        }

        if (Get-WinGet -Installed){ & $ShowText "$($App.Name) ist bereits installiert." -Final; return }
        & $ShowText "Starte WinGet-Installation..." 

        & $ShowText "Prüfe, ob WinGet bereits installiert ist..."
        Install-Script -Name Install-WinGet -Force -ErrorAction SilentlyContinue

        & $ShowText "Installiere WinGet..."
        winget-install --id=Install-WinGet -e --source=winget --silent

        # # Reserve
        # Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile winget.msixbundle
        # Add-AppPackage -ForceApplicationShutdown .\winget.msixbundle
        # Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.Winget.Source_8wekyb3d8bbwe
        # del .\winget.msixbundle
        # winget source reset --force
        
        & $ShowText "WinGet wurde erfolgreich installiert." -Final

        Show-MessageBox "InstallWinGetSuccess"
    } elseif ($InstallApps) {
        foreach ($app in $InstallApps) {
            & $AppInfo.DebugText "Installiere $($app.Name) (Id: $($app.Id), Version: $($app.Version))"
            & $ShowText "Installiere $($app.Name)..."
            
            try { 
                Start-Command "winget install --id=$($app.Id) --source=winget --silent"
            } catch { 
                & $ShowText "Fehler beim Installieren von $($app.Name) mit 'winget install'`: $_"
                try { 
                    Start-Command "Install-WinGetPackage -Id $($app.Id) -Silent"
                } catch { 
                    & $ShowText "Fehler beim Installieren von $($app.Name) mit 'Install-WinGetPackage'`: $_"
                }
            }
        }
        & $ShowText "Installation abgeschlossen." -Final
        return
    } elseif ($Installed) {
        $WinGetModule = Get-Module -ListAvailable -Name Microsoft.WinGet.Client
        if ($WinGetModule) { return $true } else { return $false }
    } elseif ($List) {
        if ($Setup){
            $SetupList = [ordered]@{
                "7Zip.7zip"                         = "7-Zip"
                "Bitwarden.Bitwarden"               = "Bitwarden"
                "Discord.Discord"                   = "Discord"
                "Dropbox.Dropbox"                   = "Dropbox"
                "Google.Chrome"                     = "Google Chrome"
                "Google.GoogleDrive"                = "Google Drive"
                "Greenshot.Greenshot"               = "Greenshot"
                "KDE.Kate"                          = "Kate"
                "KeePassXCTeam.KeePassXC"           = "KeePassXC"
                "TheDocumentFoundation.LibreOffice" = "LibreOffice"
                "Microsoft.Edge"                    = "Microsoft Edge"
                "9WZDNCRFJBH4"                      = "Microsoft Photos"
                "Mozilla.Firefox"                   = "Mozilla Firefox"
                "Mozilla.Thunderbird"               = "Mozilla Thunderbird"
                "Notepad++.Notepad++"               = "Notepad++"
                "SSHFS-Win.SSHFS-Win"               = "SSHFS-Win"
                "Valve.Steam"                       = "Steam"
                "TeamSpeakSystems.TeamSpeakClient"  = "TeamSpeak 3 Client"
                "Devolutions.UniGetUI"              = "UniGetUI"
                
            }
            $AppList = foreach ($key in $SetupList.Keys) {
                [PSCustomObject]@{
                    Id      = $key
                    Name    = $SetupList[$key]
                }
            }
        } else {
            $WinGetPackages = Get-WinGetPackage -Source "winget" -Verbose | Where-Object { $_.Source -eq "winget" }
            $WinGetApps = foreach ($pkg in $WinGetPackages) {
                [PSCustomObject]@{
                    Id                  = $pkg.Id
                    Name                = $pkg.Name                    
                }
            } 
            $AppList = $WinGetApps | Sort-Object Name
        }
        return $AppList
    } elseif ($SetupList) {
        & $AppInfo.DebugText "Funktion 'Get-WinGet -SetupList' aufgerufen. Bereite die Liste der verfügbaren Apps für die Installation vor..."
        $Items = [ordered]@{
                "7Zip.7zip"                         = "7-Zip"
                "Bitwarden.Bitwarden"               = "Bitwarden"
                "Discord.Discord"                   = "Discord"
                "Dropbox.Dropbox"                   = "Dropbox"
                "Google.Chrome"                     = "Google Chrome"
                "Google.GoogleDrive"                = "Google Drive"
                "Greenshot.Greenshot"               = "Greenshot"
                "KDE.Kate"                          = "Kate"
                "KeePassXCTeam.KeePassXC"           = "KeePassXC"
                "TheDocumentFoundation.LibreOffice" = "LibreOffice"
                "Microsoft.Edge"                    = "Microsoft Edge"
                "9WZDNCRFJBH4"                      = "Microsoft Photos"
                "Mozilla.Firefox"                   = "Mozilla Firefox"
                "Mozilla.Thunderbird"               = "Mozilla Thunderbird"
                "Notepad++.Notepad++"               = "Notepad++"
                "SSHFS-Win.SSHFS-Win"               = "SSHFS-Win"
                "Valve.Steam"                       = "Steam"
                "TeamSpeakSystems.TeamSpeakClient"  = "TeamSpeak 3 Client"
                "Devolutions.UniGetUI"              = "UniGetUI"
        }
        $AppList = foreach ($key in $Items.Keys) {
            [PSCustomObject]@{
                Id      = $key
                Name    = $Items[$key]
            }
        }
        & $AppInfo.DebugText "Rückgabewerte von Get-WinGet -SetupList: `$AppList = $($AppList | Out-String)"
        return $AppList
    } elseif ($Uninstall) {
        if(-not (Show-MessageBox "ConfirmUninstallWinGet")) { & $ShowText "Deinstallation abgebrochen." -Final; return }
        else { & $ShowText "Deinstallation von WinGet wird gestartet..." }
        $WinGetName = "Microsoft.DesktopAppInstaller"

        & $ShowText "Finde WinGet-Paketinformationen..."
        $WinGetPackage = Get-WinGetPackage -Id $WinGetName -Source "winget" -ErrorAction SilentlyContinue

        & $ShowText "Entferne WinGet-Paket..."
        Remove-AppxPackage -Package $WinGetPackage.PackageFullName -AllUsers

        & $ShowText "Entferne WinGet-ProvisionedPackage..."
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*DesktopAppInstaller*" | Remove-AppxProvisionedPackage -Online

        & $ShowText "Entferne WinGet-AppxPackage für alle Benutzer..."
        Get-AppxPackage *DesktopAppInstaller* | Remove-AppxPackage -AllUsers

        & $ShowText "WinGet wurde erfolgreich deinstalliert." -Final
        Show-MessageBox "UninstallWinGetSuccess"
        
        return
    } elseif ($UninstallApps) {
        & $ShowText "Starte Deinstallation der ausgewählten Apps..."
        foreach ($app in $UninstallApps) {
            $Id     = $app.Id
            $Name   = $app.Name

            & $ShowText "Deinstalliere $Name..."
            try { 
                Start-Command "winget uninstall --id=$Id --exact --source winget --accept-source-agreements --disable-interactivity"
            } catch { 
                & $ShowText "Fehler beim Entfernen von $Name mit 'winget uninstall'`: $_"
                try { 
                    Start-Command "Uninstall-WinGetPackage -Id $Id -Silent"
                } catch { 
                    & $ShowText "Fehler beim Entfernen von $Name mit 'Uninstall-WinGetPackage'`: $_" 
                }
            }
        }
        & $ShowText "Deinstallation abgeschlossen." -Final
        return
    } elseif ($Update) {
        & $ShowText "Starte WinGet-Aktualisierung..."
        $WinGetPackage = Get-WinGetPackage -Id "Microsoft.DesktopAppInstaller" -Source "winget" -ErrorAction SilentlyContinue

        if ($WinGetPackage -and $WinGetPackage.IsUpdateAvailable) {
            & $ShowText "Update verfügbar für WinGet (Version: $($WinGetPackage.Version))"
            & $ShowText "Aktualisiere WinGet..."
            try {
                winget upgrade --id=Microsoft.DesktopAppInstaller --source=winget --silent -ErrorAction Stop
            } catch {
                & $ShowText "Fehlgeschlagen mit 'winget upgrade', versuche es mit 'Update-WinGetPackage'..."
                try {
                    Update-WinGetPackage -Id "Microsoft.DesktopAppInstaller" -Silent
                } catch {
                    & $ShowText "Fehler: WinGet konnte nicht aktualisiert werden: $_"
                }
            }
            & $ShowText "WinGet wurde erfolgreich aktualisiert." -Final
        } else {
            & $ShowText "WinGet ist bereits auf dem neuesten Stand." -Final
        }
        return
    } elseif ($UpdateApps) {
        foreach ($app in $Apps) {
            & $ShowText "Aktualisiere $($app.Name)..."
            $Id = $app.Id
            $Version = winget show --id=$($app.Id) --source=winget | Where-Object { $_ -match "^Version:" } | ForEach-Object { ($_ -split ":")[1].Trim() }

            try { & $ShowText "winget upgrade $Id"
                winget upgrade --id=$Id --exact --source winget --accept-source-agreements --disable-interactivity --version $Version --silent
            } catch { & $ShowText "Fehler beim Aktualisieren von $($app.Name) mit 'winget upgrade'`: $_"
                try { & $ShowText "Versuche es mit 'Update-WinGetPackage'..."
                    Update-WinGetPackage -Id $Id -Silent
                } catch { & $ShowText "Fehler beim Aktualisieren von $($app.Name) mit 'Update-WinGetPackage'`: $_" }
            }

            # Überprüfen, ob die Aktualisierung erfolgreich war, indem erneut nach dem Paket gesucht wird und die Version verglichen wird
            $UpdateCheck = Get-WinGetPackage -source "winget" -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq $Id }
            if ($UpdateCheck -and ($UpdateCheck.Version -ne $Version)) { & $ShowText "$($app.Name) wurde erfolgreich aktualisiert." } 
            else { & $ShowText "Fehler: $($app.Name) konnte nicht aktualisiert werden." }
        }
        & $ShowText "Alle ausgewählten Apps wurden aktualisiert." -Final
        return
    } elseif ($UpdateAvailable) {
        $WinGetPackages = Get-WinGetPackage -Source "winget" -ErrorAction SilentlyContinue
        $WinGetUpdate = $WinGetPackages | Where-Object { $_.Id -eq "Microsoft.DesktopAppInstaller" }

        if ($WinGetUpdate -and $WinGetUpdate.IsUpdateAvailable) {
            & $ShowText "Update verfügbar für WinGet (Version: $($WinGetUpdate.Version))"
            return $true
        } else {
            & $ShowText "WinGet ist auf dem neuesten Stand."
            return $false
        }
    } elseif ($Version) {
            & $ShowText "Prüfe auf installierte WinGet-Versionen..."
            # $AppVersion = (Get-WinGetVersion) -replace 'v', ''
            $modules = Get-Module -ListAvailable -Name Microsoft.WinGet.Client | Sort-Object Version -Descending
            if ($modules.Count -eq 0) {
                & $ShowText "Microsoft.WinGet.Client ist nicht installiert."
                return $null
            } elseif ($modules.Count -gt 1){

                & $ShowText "Mehrere Versionen von Microsoft.WinGet.Client gefunden. Entferne alle Versionen außer der neuesten..."
                foreach($module in $modules | Select-Object -Skip 1) { 
                    & $ShowText "Entferne Microsoft.WinGet.Client Version $($module.Version)..."
                    Uninstall-Module Microsoft.WinGet.Client -RequiredVersion $module.Version -Force 
                }
                & $ShowText "Alle älteren Versionen von Microsoft.WinGet.Client wurden entfernt."
            }
            $WinGetVersion = ($modules | Select-Object -First 1).Version.ToString()
            & $ShowText "Die installierte WinGet-Version ist: $WinGetVersion"
            return $WinGetVersion
    } else {
        & $AppLog.Info "Funktion 'Get-WinGet' aufgerufen ohne (gültige) Parameter. Überprüfe, ob WinGet installiert ist..."
        return Get-Command -Name "winget.exe" -ErrorAction SilentlyContinue
    }
}


