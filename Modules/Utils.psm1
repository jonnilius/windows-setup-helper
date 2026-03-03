<# CHOCOLATEY #>
function Read-Chocolatey {
    param ( 
        [switch]$Installed,
        [switch]$Version,
        [switch]$AppList,
        [switch]$SetupList
    )
    
    if ($AppList)         {
        Write-Verbose "Doppelter Variablename 'appList' in Funktion 'Read-Chocolatey' gefunden."

        $appList = @()
        $rawList = choco list --idonly

        foreach ($line in $rawList) {
            if ($line -match '^\d+ packages installed\.$') { break }
            if ($line -and $line -notmatch '^Chocolatey v') { $appList += $line.Trim() }
        }

        return $appList
    } elseif ($Installed) { return !([string]::IsNullOrWhiteSpace((Get-Command choco -ErrorAction SilentlyContinue).Source)) 
    } elseif ($Version)   { return (choco --version).Trim() 
    } elseif ($SetupList) { return [ordered]@{
        # Packagename bei Chocolatey | Anzeigename
        "7zip"                      = "7-Zip"
        "adobereader"               = "Adobe Acrobat Reader DC"
        "autocad"                   = "AutoCAD 2026"
        "autoruns"                  = "Autoruns"
        "boxcryptor"                = "Boxcryptor"
        "discord"                   = "Discord"
        "dropbox"                   = "Dropbox"
        "filezilla"                 = "FileZilla"
        "firefox"                   = "Mozilla Firefox"
        "googlechrome"              = "Google Chrome"
        "googledrive"               = "Google Drive"
        "greenshot"                 = "Greenshot"
        "kate"                      = "Kate"
        "keepassxc"                 = "KeePassXC"
        "libreoffice-fresh"         = "LibreOffice Fresh"
        "microsoft-teams"           = "Microsoft Teams (Classic Desktop App)"
        "nextcloud-client"          = "Nextcloud Desktop Client"
        "onedrive"                  = "OneDrive"
        "openvpn"                   = "OpenVPN"
        "openvpn-connect"           = "OpenVPN Connect"
        "qbittorrent"               = "qBittorrent"
        "pdf24"                     = "PDF24 Creator"
        "putty"                     = "PuTTY"
        "python3"                   = "Python 3.x"
        "rustdesk"                  = "RustDesk"
        "signal"                    = "Signal"
        "sshfs"                     = "SSHFS-Win"
        "steam"                     = "Steam"
        "teamspeak"                 = "TeamSpeak 3"
        "teamviewer"                = "Teamviewer"
        "teamviewer-qs"             = "Teamviewer QuickSupport"
        "thunderbird"               = "Mozilla Thunderbird"
        "ventoy"                    = "Ventoy"
        "virtualbox"                = "VirtualBox"
        "visualstudio2019community" = "Visual Studio 2019 Community"
        "vlc"                       = "VLC media player"
        "vscode"                    = "Visual Studio Code"
        "winrar"                    = "WinRAR"
        "winfsp"                    = "WinFsp"
        "winscp"                    = "WinSCP"
    }

    }

}
function Install-Chocolatey {
    # Ausführunagsrichtlinien anpassen (erlaubt für diesen Prozess unsignierte Skripte)
    Set-ExecutionPolicy Bypass -Scope Process -Force

    # Sicherheitsprotokoll anpassen (benötigt für TLS 1.2, das von Chocolatey-Servern verwendet wird)
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    # Chocolatey laden und installieren (Setup durch Chocolatey-Installationsskript)
    Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -UseBasicParsing | Invoke-Expression
}
function Uninstall-Chocolatey {
    # Umgebungsvariable für Chocolatey-Installation überprüfen
    if (-not $env:ChocolateyInstall) {
        $message = @(
            "Chocolatey ist nicht installiert oder die Umgebungsvariable fehlt."
        ) -join "`n"

        Write-Warning $message
        return
    }
    if (-not (Test-Path $env:ChocolateyInstall)) {
        $message = @(
            "Keine Chocolatey-Installation unter '$env:ChocolateyInstall' gefunden."
            "Keine weitere Verarbeitung notwendig."
        ) -join "`n"

        Write-Warning $message
        return
    }

    <#
        Hier werden bewusst die .NET-Registry-Aufrufe verwendet, um in PATH-Werten eingebettete
        Umgebungsvariablen zu erhalten. Der PowerShell-Registry-Provider bietet keine Möglichkeit,
        Variablenreferenzen unverändert beizubehalten. Wir möchten vermeiden, dass diese versehentlich
        durch absolute Pfadangaben überschrieben werden.

        Während die Registry beispielsweise "%SystemRoot%" in einem PATH-Eintrag anzeigt,
        sieht der PowerShell-Registry-Provider lediglich "C:\Windows".
    #>
    $userKey  = [Registry]::CurrentUser.OpenSubKey('Environment', $true)
    $userPath = $userKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()

    $machineKey  = [Registry]::LocalMachine.OpenSubKey('SYSTEM\ControlSet001\Control\Session Manager\Environment\', $true)
    $machinePath = $machineKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()
    
    $backupFile  = "C:\PATH_backups_ChocolateyUninstall.txt"
    $backupPATHs = @(
        "User PATH: $userPath"
        "Machine PATH: $machinePath"
    )
    $backupPATHs | Set-Content -Path $backupFile -Encoding UTF8 -Force

    $warningMessage = @"
Dies kann nach einem Neustart zu Problemen führen, wenn bei der Änderung des PATH etwas schiefgeht.
In diesem Fall findest du die ursprünglichen PATH-Werte in der Sicherungsdatei unter '$backupFile'.
"@

    # Chocolatey-Installationspfad aus PATH entfernen, falls vorhanden
    if ($userPath -like "*$env:ChocolateyInstall*") {
        Write-Verbose "Chocolatey-Installationspfad im Benutzer-PATH gefunden. Wird entfernt..."
        Write-Warning $warningMessage

        $newUserPATH = @(
            $userPath -split [System.IO.Path]::PathSeparator |
            Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }
        ) -join [System.IO.Path]::PathSeparator

        # NEVER use [Environment]::SetEnvironmentVariable() for PATH values; see https://github.com/dotnet/corefx/issues/36449
        # This issue exists in ALL released versions of .NET and .NET Core as of 12/19/2019
        $userKey.SetValue('PATH', $newUserPATH, 'ExpandString')
    }
    if ($machinePath -like "*$env:ChocolateyInstall*") {
        Write-Verbose "Chocolatey-Installationspfad im System-PATH gefunden. Wird entfernt..."
        Write-Warning $warningMessage

        $newMachinePATH = @(
            $machinePath -split [System.IO.Path]::PathSeparator |
            Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }
        ) -join [System.IO.Path]::PathSeparator

        # NEVER use [Environment]::SetEnvironmentVariable() for PATH values; see https://github.com/dotnet/corefx/issues/36449
        # This issue exists in ALL released versions of .NET and .NET Core as of 12/19/2019
        $machineKey.SetValue('PATH', $newMachinePATH, 'ExpandString')
    }

    # Anpassung für Dienste, die in Unterordnern von ChocolateyInstall ausgeführt werden
    $agentService = Get-Service -Name chocolatey-agent -ErrorAction SilentlyContinue
    if ($agentService -and $agentService.Status -eq 'Running') {
        $agentService.Stop()
    }
    # TODO: Weitere relevante Dienste hier ergänzen

    Remove-Item -Path $env:ChocolateyInstall -Recurse -Force

    'ChocolateyInstall', 'ChocolateyLastPathUpdate' | ForEach-Object {
        foreach ($scope in 'User', 'Machine') { 
            [Environment]::SetEnvironmentVariable($_, [string]::Empty, $scope)
        }
    }

    $machineKey.Close()
    $userKey.Close()
    if ($env:ChocolateyToolsLocation -and (Test-Path $env:ChocolateyToolsLocation)) {
        Remove-Item -Path $env:ChocolateyToolsLocation -Recurse -Force
    }

    foreach ($scope in 'User', 'Machine') {
        [Environment]::SetEnvironmentVariable('ChocolateyToolsLocation', [string]::Empty, $scope)
    }
}

<# TOOLS #>
function ChangeDeviceName {
    param (
        [string]$NewName
    )
    if ($NewName -eq "") {
        [System.Windows.Forms.MessageBox]::Show("Der Gerätename wurde nicht geändert!", "Fehler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    else {
        Rename-Computer -NewName $NewName -Force
        [System.Windows.Forms.MessageBox]::Show("Der Gerätename wurde erfolgreich geändert! `nIhr neuer Gerätename: $NewName", "Erfolg", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        [System.Windows.Forms.MessageBox]::Show("Der Computer muss neu gestartet werden, damit die Änderung wirksam wird!", "Neustart erforderlich", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
}
function RemoveOneDrive {
    # Erstelle das Formular
    $Form = New-Object System.Windows.Forms.Form
    $Form.ClientSize = New-Object System.Drawing.Size(300,100)
    $Form.Padding = New-Object System.Windows.Forms.Padding(10)
    $Form.StartPosition = "CenterScreen"
    $Form.Text = "Entferne OneDrive..."
    $Form.BackColor = [ColorTranslator]::FromHtml("#C0393B")

    # Erstelle ein Panel
    $Panel = New-Object System.Windows.Forms.Panel
    $Panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $Panel.BackColor = [ColorTranslator]::FromHtml("#2D3436")
    $Form.Controls.Add($Panel)

    # Erstelle ein Label
    $Label = New-Object System.Windows.Forms.Label
    $Label.Dock = [System.Windows.Forms.DockStyle]::Fill
    $Label.TextAlign = [ContentAlignment]::MiddleCenter
    $Label.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $Label.Text = "OneDrive wird entfernt. Bitte warten..."
    $Panel.Controls.Add($Label)

    # Zeige das Formular an
    $Form.Show()

    # OneDrive überprüfen
    $Label.Text = "Überprüfe OneDrive-Ordner..."
    if (Test-Path "$env:USERPROFILE\OneDrive\*") {
        $Label.Text = "OneDrive-Ordner ist nicht leer..."
        Start-Sleep -Seconds 1

        $confirm = [System.Windows.Forms.MessageBox]::Show("Der OneDrive-Ordner enthält Dateien. Möchten Sie diese sichern, bevor OneDrive deinstalliert wird?", "OneDrive-Ordner nicht leer", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) { 
            # Backup-Ordner auf dem Desktop erstellen, falls er nicht existiert
            $Label.Text = "Sichere Dateien..."
            if (!(Test-Path "$env:USERPROFILE\Desktop\OneDriveBackupFiles")) {
                $Label.Text = "Erstelle Ordner 'OneDriveBackupFiles' auf dem Desktop. Alle Dateien werden in diesen Ordner verschoben."
                New-Item -Path "$env:USERPROFILE\Desktop" -Name "OneDriveBackupFiles" -ItemType Directory -Force
                Start-Sleep -Seconds 1
            }

            # OneDrive-Ordnerinhalt in den Backup-Ordner verschieben
            Move-Item -Path "$env:USERPROFILE\OneDrive\*" -Destination "$env:USERPROFILE\Desktop\OneDriveBackupFiles" -Force
            $Label.Text = "Alle Dateien wurden in den Ordner 'OneDriveBackupFiles' auf dem Desktop verschoben."
            Start-Sleep -Seconds 1
        } else {
            $Label.Text = "OneDrive-Ordner wird nicht gesichert. `nFahre mit der Deinstallation fort..."
            Start-Sleep -Seconds 1
        }
    } else {
        $Label.Text = "OneDrive-Ordner ist leer..."
        Start-Sleep -Seconds 1
    }

    # OneDrive deinstallieren
    $Label.Text = "Erfasse OneDrive-Informationen..."
    New-PSDrive  HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    $OneDrive = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
    $ExplorerReg1 = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    $ExplorerReg2 = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"

    # OneDrive-Prozesse beenden
    $Label.Text = "Beende OneDrive-Prozesse..."
    Stop-Process -Name "OneDrive*"
    Stop-Process -Name "Microsoft OneDriveFile*"
    Start-Sleep -Seconds 2

    # Richtige OneDrive-Setup-Datei ermitteln und deinstallieren
    If (!(Test-Path $OneDrive)) { $OneDrive = "$env:SYSTEMROOT\System32\OneDriveSetup.exe" }
    Start-Process $OneDrive "/uninstall" -NoNewWindow -Wait
    Start-Sleep -Seconds 2

    # Datei-Explorer beenden
    $Label.Text = "Beende Datei-Explorer..."
    Start-Sleep -Seconds 1
    taskkill.exe /F /IM explorer.exe
    Start-Sleep -Seconds 3

    # Verbleibende Dateien entfernen
    $Label.Text = "Entferne verbleibende Dateien..."
    Remove-Item "$env:USERPROFILE\OneDrive" -Force -Recurse
    Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse
    Remove-Item "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse
    If (Test-Path "$env:SYSTEMDRIVE\OneDriveTemp") { Remove-Item "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse }
    Start-Sleep -Seconds 1

    # OneDrive aus dem Windows Explorer entfernen
    $Label.Text = "Entferne OneDrive aus dem Windows Explorer..."
    If (!(Test-Path $ExplorerReg1)) { New-Item $ExplorerReg1 }
    Set-ItemProperty $ExplorerReg1 System.IsPinnedToNameSpaceTree -Value 0 
    If (!(Test-Path $ExplorerReg2)) { New-Item $ExplorerReg2 }
    Set-ItemProperty $ExplorerReg2 System.IsPinnedToNameSpaceTree -Value 0
    Start-Sleep -Seconds 1

    # Starte den zuvor beendeten Explorer neu
    $Label.Text = "Starte den zuvor beendeten Explorer neu..."
    Start-Process explorer.exe -NoNewWindow
    Start-Sleep -Seconds 2

    # Aktiviere die Gruppenrichtlinie 'Verweigern der Verwendung von OneDrive für die Dateispeicherung'
    $Label.Text = "Aktiviere die Gruppenrichtlinie 'Verweigern der Verwendung von OneDrive für die Dateispeicherung'..."
    $OneDriveKey = 'HKLM:Software\Policies\Microsoft\Windows\OneDrive'
    If (!(Test-Path $OneDriveKey)) { Mkdir $OneDriveKey }
    Set-ItemProperty $OneDriveKey -Name OneDrive -Value DisableFileSyncNGSC
    Start-Sleep -Seconds 1

    # Abschließende Meldung anzeigen
    $Label.Text = "OneDrive wurde erfolgreich deinstalliert!"
    Start-Sleep -Seconds 2


    # Fenster schließen
    $Form.Close()
    $Form.Dispose()
}
function UnpinStartMenuIcons {
    # Erstelle das Formular
    $Form = New-Object System.Windows.Forms.Form
    $Form.ClientSize = New-Object System.Drawing.Size(300,120)
    $Form.Padding = New-Object System.Windows.Forms.Padding(10)
    $Form.StartPosition = "CenterScreen"
    $Form.Text = "Startmenü-Icons entfernen..."
    $Form.BackColor = [ColorTranslator]::FromHtml("#C0393B")

    # Erstelle ein Panel
    $Panel = New-Object System.Windows.Forms.Panel
    $Panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $Panel.BackColor = [ColorTranslator]::FromHtml("#2D3436")
    $Form.Controls.Add($Panel)

    # Erstelle ein Label
    $Label = New-Object System.Windows.Forms.Label
    $Label.Dock = [System.Windows.Forms.DockStyle]::Fill
    $Label.TextAlign = [ContentAlignment]::MiddleCenter
    $Label.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $Label.Text = "Startmenü-Icons werden entfernt. Bitte warten..."
    $Panel.Controls.Add($Label)

    # Fenster anzeigen
    $Form.Show()

    # Definiere Startmenü-Layout als XML-String
    $START_MENU_LAYOUT = @"
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
<LayoutOptions StartTileGroupCellWidth="6" />
<DefaultLayoutOverride>
    <StartLayoutCollection>
        <defaultlayout:StartLayout GroupCellWidth="6" />
    </StartLayoutCollection>
</DefaultLayoutOverride>
</LayoutModificationTemplate>
"@
    $layoutFile="C:\Windows\StartMenuLayout.xml"

    # Lösche die Layout-Datei, falls sie bereits existiert
    If ( Test-Path $layoutFile ) { Remove-Item $layoutFile }

    # Erstelle die neue Layout-Datei mit dem definierten XML-Layout
    $START_MENU_LAYOUT | Out-File $layoutFile -Encoding ASCII

    $regAliases = @("HKLM", "HKCU")

    # Weisen Sie das Startlayout zu und erzwingen Sie die Anwendung mit "LockedStartLayout" sowohl auf Maschinen- als auch auf Benutzerebene
    foreach ($regAlias in $regAliases){
        $basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
        $keyPath = $basePath + "\Explorer" 
        IF(!(Test-Path -Path $keyPath)) { 
            New-Item -Path $basePath -Name "Explorer"
        }
        Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 1
        Set-ItemProperty -Path $keyPath -Name "StartLayoutFile" -Value $layoutFile
    }

    # Explorer neu starten, damit die Änderungen wirksam werden. 
    # Das Startmenü-Layout wird nun auf das definierte XML-Layout gesetzt, und die Benutzer können keine Änderungen daran vornehmen.
    Stop-Process -name explorer
    Start-Sleep -Seconds 5
    $wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^{ESCAPE}')
    Start-Sleep -Seconds 5

    # Entfernen der Sperre, damit Benutzer das Startmenü-Layout wieder anpassen können, falls gewünscht.
    foreach ($regAlias in $regAliases){
        $basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
        $keyPath = $basePath + "\Explorer" 
        Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 0
    }

    # Explorer neu starten und die Layout-Datei löschen
    Stop-Process -name explorer

    # Das neue Startmenü-Layout wird sofort angewendet, und die Benutzer können es nach dem Neustart des Explorers anpassen, wenn sie möchten.
    Import-StartLayout -LayoutPath $layoutFile -MountPath $env:SystemDrive\
    Remove-Item $layoutFile

    # Abschließende Meldung anzeigen
    $Label.Text = "Startmenü-Icons wurden erfolgreich entfernt!"
    Start-Sleep -Seconds 5

    # Fenster schließen
    $Form.Close()
    $Form.Dispose()

}
