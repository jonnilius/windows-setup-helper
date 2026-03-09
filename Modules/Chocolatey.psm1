function Read-Chocolatey {
    param ( 
        [switch]$Installed,
        [switch]$Version,
        [switch]$AppList,
        [switch]$SetupList
    )
    
    if ($AppList)         {
        Write-Verbose "Doppelter Variablename 'appList' in Funktion 'Read-Chocolatey' gefunden."

        $apkList = @()
        $rawList = choco list --idonly

        foreach ($line in $rawList) {
            if ($line -match '^\d+ packages installed\.$') { break }
            if ($line -and $line -notmatch '^Chocolatey v') { $apkList += $line.Trim() }
        }

        return $apkList
    } elseif ($Installed) { return !([string]::IsNullOrWhiteSpace((Get-Command choco -ErrorAction SilentlyContinue).Source)) 
    } elseif ($Version)   { return (choco --version).Trim() 
    } elseif ($SetupList) { return [ordered]@{
        # Packagename bei Chocolatey | Anzeigename
        "7zip"                      = "7-Zip"
        "adb"                       = "Android Debug Bridge (ADB)"
        "adobereader"               = "Adobe Acrobat Reader DC"
        "autocad"                   = "AutoCAD 2026"
        "autoruns"                  = "Autoruns"
        "boxcryptor"                = "Boxcryptor"
        "discord"                   = "Discord"
        "dropbox"                   = "Dropbox"
        "filezilla"                 = "FileZilla"
        "googlechrome"              = "Google Chrome"
        "googledrive"               = "Google Drive"
        "greenshot"                 = "Greenshot"
        "kate"                      = "Kate"
        "keepassxc"                 = "KeePassXC"
        "libreoffice-fresh"         = "LibreOffice Fresh"
        "dotnetfx"                  = "Microsoft .NET Framework"
        "netfx-4.8-dev"             = "Microsoft .NET Framework 4.8 Developer Pack"
        "dotnet-sdk"                = "Microsoft .NET SDK"
        "microsoft-teams"           = "Microsoft Teams (Classic Desktop App)"
        "firefox"                   = "Mozilla Firefox"
        "thunderbird"               = "Mozilla Thunderbird"
        "nextcloud-client"          = "Nextcloud Desktop Client"
        "onedrive"                  = "OneDrive"
        "openvpn"                   = "OpenVPN"
        "openvpn-connect"           = "OpenVPN Connect"
        "qbittorrent"               = "qBittorrent"
        "pdf24"                     = "PDF24 Creator"
        "putty"                     = "PuTTY"
        "python3"                   = "Python 3.x"
        "rustdesk"                  = "RustDesk"
        "scrcpy"                    = "scrcpy"
        "signal"                    = "Signal"
        "sshfs"                     = "SSHFS-Win"
        "steam"                     = "Steam"
        "teamspeak"                 = "TeamSpeak 3"
        "teamviewer"                = "Teamviewer"
        "teamviewer-qs"             = "Teamviewer QuickSupport"
        "ventoy"                    = "Ventoy"
        "virtualbox"                = "VirtualBox"
        "visualstudio2019buildtools"= "Visual Studio 2019 Build Tools"
        "visualstudio2019community" = "Visual Studio 2019 Community"
        "vscode"                    = "Visual Studio Code"
        "vlc"                       = "VLC media player"
        "winfsp"                    = "WinFsp"
        "winrar"                    = "WinRAR"
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
    $userKey  = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
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


function UpdateChocoApps {
    param ( $form )

    # Prozesslabel für Statusinformationen abrufen und initialisieren
    $processLabel           = $form.Controls.Find("ProcessInfoLabel", $true)[0]
    $processLabel.Text      = "Aktualisiere ausgewählte Pakete..."
    $processLabel.Visible   = $true
    
    # Update- und Deinstallationsbuttons abrufen
    $updateButton = $form.Controls.Find("UpdateButton", $true)[0]
    $removeButton = $form.Controls.Find("UninstallButton", $true)[0]
    
    # Cursor auf "Ladevorgang" setzen und ausgewählte Pakete abrufen
    $form.Cursor            = [Cursors]::AppStarting
    $packagesList           = $form.Controls.Find("ListBox", $true)[0]
    $selectedPackages       = @($packagesList.SelectedItems)
    Start-Sleep -Seconds 1

    choco upgrade ($selectedPackages -join ' ') -y | Out-Null

    # Aktualisierung abgeschlossen
    $form.Cursor        = [Cursors]::Default
    $processLabel.Text  = "Alle ausgewählten Pakete wurden aktualisiert."
    $packagesList.SelectedItems.Clear()
    $packagesList.Items.Clear()

    # App-Liste neu laden und UI-Elemente zurücksetzen
    $appList = Read-Chocolatey -AppList
    $updateButton.Visible = $false
    $removeButton.Visible = $false
    $processLabel.Visible = $false
    foreach ($program in $appList) {
        $packagesList.Items.Add($program) | Out-Null
    }
    # $form.Controls["SidebarPanel"].Enabled = $true
    Start-Sleep -Seconds 2
    Show-MessageBox "PackagesUpdated"
}
function UninstallChocoApps {
    param ($button)
    
    $form = $button.FindForm()
    $packagesList = $form.Controls.Find("ListBox", $true)[0]
    $processLabel = $form.Controls.Find("ProcessInfoLabel", $true)[0]

    $updateButton = $form.Controls.Find("UpdateButton", $true)[0]
    $removeButton = $form.Controls.Find("UninstallButton", $true)[0]
    $selectedPackages = @($packagesList.SelectedItems)
    
    $form.Cursor = [Cursors]::AppStarting
    $processLabel.Visible = $true
    Start-Sleep -Seconds 1

    foreach ($package in $selectedPackages) {
        $processLabel.Text = "Deinstalliere $package..."
        Start-Sleep -Seconds 1
        choco uninstall $package -y | Out-Null
        $packagesList.Items.Remove($package)
        Start-Sleep -Seconds 1
        $processLabel.Text = "Deinstallation von $package abgeschlossen."
    }

    $form.Cursor = [Cursors]::Default
    $processLabel.Text = "Alle ausgewählten Pakete wurden deinstalliert."
    $removeButton.Visible = $false
    $processLabel.Visible = $false
    $updateButton.Visible = $false
    Start-Sleep -Seconds 2
    Show-MessageBox "PackagesUninstalled"
}
function ChocolateyForm {
    param($FormConfig)
    $Form = New-Form $FormConfig.Chocolatey
    $Form.ShowDialog()
}