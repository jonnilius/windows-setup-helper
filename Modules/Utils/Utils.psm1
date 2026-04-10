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
function Show-MessageBox {
    param (
        [string]$Config,
        [string]$Text,
        [string]$Caption = "Information",
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
            $Text = "Unbekannte Konfiguration: $Config"
            $Caption = "Fehler"
            $Icon = "Error"
            $Buttons = "OK"
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
        Show-DialogBox -Message "Der Gerätename wurde nicht geändert!" -Title "Fehler" -Buttons "OK" -Icon "Error"
    }
    else {
        Rename-Computer -NewName $NewName -Force
        Show-DialogBox -Message "Der Gerätename wurde erfolgreich geändert! `nIhr neuer Gerätename: $NewName" -Title "Erfolg" -Buttons "OK" -Icon "Information"
        Show-DialogBox -Message "Der Computer muss neu gestartet werden, damit die Änderung wirksam wird!" -Title "Neustart erforderlich" -Buttons "OK" -Icon "Warning"
    }
}

function Watch-Empty {
    param ( $Value )
    
    if ($Value -is [string]) { return [string]::IsNullOrWhiteSpace($Value) }
    else { return $false }
}
function Test-Empty {
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

function Show-DialogBox {
    <#
    .SYNOPSIS
        Zeigt ein Dialogfeld mit einer Nachricht, einem Titel, Schaltflächen und einem Symbol an.
    .PARAMETER Message
        Die anzuzeigende Nachricht.
    .PARAMETER Title
        Der Titel des Dialogfelds.
    .PARAMETER Buttons
        Die anzuzeigenden Schaltflächen (z. B. "OK", "YesNo").
    .PARAMETER Icon
        Das anzuzeigende Symbol (z. B. "None", "Information", "Warning", "Error").
    .EXAMPLE
        Show-DialogBox -Message "Dies ist eine Nachricht" -Title "Titel" -Buttons "OK" -Icon "Information"
    #>
    param (
        [string]$Message,
        [string]$Title,
        [string]$Buttons,
        [string]$Icon
    )
    if (-not $Message)  { throw "Der Parameter 'Message' ist erforderlich." }
    if (-not $Title)    { throw "Der Parameter 'Title' ist erforderlich." }
    # Konvertiere die Button-Parameter in die entsprechenden Enums
    switch ($Buttons) {
        "OK"    { $Buttons = [System.Windows.Forms.MessageBoxButtons]::OK }
        "YesNo" { $Buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo }
        default { $Buttons = [System.Windows.Forms.MessageBoxButtons]::OK }
    }
    # Konvertiere die Icon-Parameter in die entsprechenden Enums
    switch ($Icon) {
        "None"          { $Icon = [System.Windows.Forms.MessageBoxIcon]::None }
        "Information"   { $Icon = [System.Windows.Forms.MessageBoxIcon]::Information }
        "Warning"       { $Icon = [System.Windows.Forms.MessageBoxIcon]::Warning }
        "Error"         { $Icon = [System.Windows.Forms.MessageBoxIcon]::Error }
        default         { $Icon = [System.Windows.Forms.MessageBoxIcon]::None }
    }

    $result = [System.Windows.Forms.MessageBox]::Show($Message, $Title, $Buttons, $Icon)

    if ($Buttons -eq [System.Windows.Forms.MessageBoxButtons]::YesNo) {
        return $result -eq [System.Windows.Forms.DialogResult]::Yes
    }

    return $result -eq [System.Windows.Forms.DialogResult]::OK
}


function Uninstall-App {
    param ( $take, [string]$AppName )
    & $AppLog.Info "Funktion 'Uninstall-App' aufgerufen mit AppName: $AppName"
    
    $RootPath = $AppInfo.Path

    switch ($AppName) {
        "Edge"           { & "$RootPath\Debloat\Uninstall-MicrosoftEdge.ps1" $take; break }
        "OneDrive"       { & "$RootPath\Debloat\Uninstall-OneDrive.ps1" $take; break }
        "WinGet"         { & "$RootPath\Debloat\Uninstall-WinGet.ps1" $take; break }
        default          { & $AppLog.Error "Unbekannter AppName: $AppName" }
    }
}

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


<# ENERGIEOPTIONEN #>
function Get-PowerStatus {
    param ( 
        [ValidateSet("AC", "DC")]
        [string]$PowerScheme = "AC", 
        [string]$StatusType = "Standby", 
        [switch]$ReturnSeconds,
        [switch]$TextOutput
        )

    $result = switch ($StatusType) {
        "Standby"   { powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE }
        "Hibernate" { powercfg /query SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE }
        "Monitor"   { powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE }
        default     { throw "Ungültiger StatusType. Verwenden Sie 'Standby', 'Hibernate' oder 'Monitor'." }
    }
    $powerString    = if ($PowerScheme -eq "AC") { "Wechselstrom" } elseif ($PowerScheme -eq "DC") { "Gleichstrom" }
    $value          = ($result | Select-String $powerString).ToString().Split(":")[-1].Trim()
    $seconds        = [convert]::ToInt32($value, 16)
    $minutes        = $seconds / 60

    # Rückgabe basierend auf den Parametern
    if ($TextOutput -and $seconds -eq 0) { return "Nie" }
    elseif ($TextOutput -and $ReturnSeconds) { return "$seconds Sekunden" } 
    elseif ($TextOutput) { return "$minutes Minuten" } 
    elseif ($ReturnSeconds) { return $seconds } 
    else { return $minutes }
}
function Set-PowerStatus {
    param ( [ValidateSet("AC", "DC")][string]$PowerScheme = "AC", [string]$StatusType = "Standby", [int]$Minutes )

    if ($Minutes -lt 0) { throw "Ungültige Minutenanzahl. Bitte geben Sie eine positive Zahl ein." }

    switch ($StatusType) {
        "Standby"   { if ($PowerScheme -eq "AC") { powercfg /change standby-timeout-ac $Minutes } elseif ($PowerScheme -eq "DC") { powercfg /change standby-timeout-dc $Minutes }}
        "Hibernate" { if ($PowerScheme -eq "AC") { powercfg /change hibernate-timeout-ac $Minutes } elseif ($PowerScheme -eq "DC") { powercfg /change hibernate-timeout-dc $Minutes }}
        "Monitor"   { if ($PowerScheme -eq "AC") { powercfg /change monitor-timeout-ac $Minutes } elseif ($PowerScheme -eq "DC") { powercfg /change monitor-timeout-dc $Minutes }}
        default     { throw "Ungültiger StatusType. Verwenden Sie 'Standby', 'Hibernate' oder 'Monitor'." }
    }
}
function Update-PowerStatus {
    param ( [ValidateSet("AC", "DC")][string]$PowerScheme = "AC", [string]$StatusType = "Standby" )

    $CurrentMinutes = Get-PowerStatus -PowerScheme $PowerScheme -StatusType $StatusType
    $GroupBoxText   = if ($StatusType -eq "Standby") { "Energiesparmodus " } elseif ($StatusType -eq "Hibernate") { "Ruhezustand " } elseif ($StatusType -eq "Monitor") { "Bildschirm ausschalten " }
    $GroupBoxText  += if ($PowerScheme -eq "AC") { "(Netzbetrieb)" } elseif ($PowerScheme -eq "DC") { "(Akkubetrieb)" }

    $Config = @{
        Properties = @{
            Text        = "Energieoptionen Ändern"
            ClientSize  = [Size]::new(280,60)
            MinimizeBox = $false
            MaximizeBox = $false
            KeyPreview  = $true
            FormBorderStyle = "FixedDialog"
            Padding     = [Padding]::new(5)
            BackColor   = Get-Color "Dark"
        }
        Controls = [ordered]@{
            GroupBox = @{
                Control     = "GroupBox"
                Text        = $GroupBoxText
                Dock        = "Fill"
                Controls    = [ordered]@{
                    TestTable = @{
                        Control     = "TableLayoutPanel"
                        Dock        = "Fill"
                        Column      = @(50, "AutoSize", "40")
                        Row         = @(30)
                        Controls    = [ordered]@{
                            Minutes = @{
                                Control     = "NumericUpDown"
                                Value       = $CurrentMinutes
                                Font        = Get-Font "Value"
                                Dock        = "Fill"
                                Minimum     = 0
                                Increment   = 5
                                Maximum     = 999
                                Add_KeyPress = { 
                                    # Akzeptiere nur Ziffern
                                    if (-not [char]::IsDigit($_.KeyChar) -and $_.KeyChar -ne [char]8) { $_.Handled = $true } 
                                    # Begrenze die Eingabe auf maximal 3 Zeichen
                                    elseif ($this.Text.Length -ge 3 -and $_.KeyChar -ne [char]8) { $_.Handled = $true }
                                }
                            }
                            MinutesLabel = @{
                                Control     = "Label"
                                Text        = "Minuten"
                                Font        = Get-Font "Label"
                                Dock        = "Fill"
                                TextAlign   = "MiddleLeft"
                            }
                            ChangeButton = @{
                                Control     = "Button"
                                Name        = "ChangeButton"
                                Text        = "Ändern"
                                Font        = Get-Font "Button"
                                Dock        = "Fill"
                                Add_Click    = {
                                    $form = $this.FindForm()
                                    [int]$minutes = $this.Parent.Controls["Minutes"].Text
                                    Set-PowerStatus -PowerScheme $PowerScheme -StatusType $StatusType -Minutes $minutes
                                    $form.Close()
                                }
                            }
                        }
                    }
                }
            }
        }
        Events = @{
            KeyDown = {
                # Bestätigt die Eingabe, wenn die Enter-Taste gedrückt wird, aber nur wenn der Fokus auf dem Minuten-Textfeld liegt
                if ($this.ActiveControl.Name -eq "Minutes") {
                    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                        $this.Controls["GroupBox"].Controls["TestTable"].Controls["ChangeButton"].PerformClick()
                    }
                }
            }
        }
    }
    Start-Form $Config
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
