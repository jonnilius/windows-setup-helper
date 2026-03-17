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
    } elseif ($SetupList) { 
        $list = [ordered]@{
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
        $list = $list.GetEnumerator()
        return $list
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

function InstallChocoApps {
    param ( $form )

    $AddTab     = $form.Controls["PackagePanel"].Controls["TabControl"].Controls["AddTab"]
    $addList    = $AddTab.Controls["AddList"]
    $process    = $AddTab.Controls["Process"]

    $addList.Visible   = $false
    $process.Visible   = $true
    $process.Text      = "Installiere ausgewählte Pakete...`n`n"
    
    # Cursor auf "Ladevorgang" setzen und angehakete Pakete abrufen
    $form.Cursor            = [Cursors]::AppStarting
    $selectedPackages       = @($addList.CheckedItems | ForEach-Object { $_.Id })

    if ($selectedPackages.Count -eq 0) {
        $form.Cursor = [Cursors]::Default
        $process.Visible = $false
        $addList.Visible = $true
        return
    }
    foreach ($package in $selectedPackages) {
        Start-Sleep -Seconds 1

        $process.Text += "Installiere $package...`n"
        choco install $package -y

        $process.Text += "Abgeschlossen.`n`n"
        Start-Sleep -Seconds 1
    }

    # Installation abgeschlossen
    $form.Cursor        = [Cursors]::Default
    $process.Text      += "Alle ausgewählten Pakete wurden installiert."
    
    Start-Sleep -Seconds 2
    $process.Visible = $false
    $addList.Visible = $true
    $addList.ClearSelected()
    foreach ($package in $addList.CheckedIndices) {
        $addList.SetItemChecked($package, $false)
    }
    Show-MessageBox "PackagesInstalled"
}
function UpdateChocoApps {
    param ( $form )

    $manageTab      = $form.Controls["PackagePanel"].Controls["TabControl"].Controls["ManageTab"]
    $installedList  = $manageTab.Controls["InstalledList"]
    $process        = $manageTab.Controls["Process"]

    $installedList.Visible  = $false
    $process.Visible        = $true

    # Prozesslabel für Statusinformationen abrufen und initialisieren
    $process.Text      = "Aktualisiere ausgewählte Pakete...`n`n"
    
    # Cursor auf "Ladevorgang" setzen und ausgewählte Pakete abrufen
    $form.Cursor            = [Cursors]::AppStarting
    $selectedPackages       = @($installedList.SelectedItems)
    Start-Sleep -Seconds 1

    foreach ($package in $selectedPackages) {
        $process.Text += "Aktualisiere $package...`n"
        Start-Sleep -Seconds 1
        choco upgrade $package -y
        $process.Text += "Abgeschlossen.`n`n"
        Start-Sleep -Seconds 1
    }

    # Aktualisierung abgeschlossen
    $form.Cursor        = [Cursors]::Default
    $process.Text  += "Alle ausgewählten Pakete wurden aktualisiert.`n"
    
    # $form.Controls["SidebarPanel"].Enabled = $true
    Start-Sleep -Seconds 2
    $process.Visible = $false
    $installedList.Visible = $true
    $installedList.ClearSelected()
    Show-MessageBox "PackagesUpdated"
}
function UninstallChocoApps {
    param ($form)

    $manageTab      = $form.Controls["PackagePanel"].Controls["TabControl"].Controls["ManageTab"]
    $installedList  = $manageTab.Controls["InstalledList"]
    $process        = $manageTab.Controls["Process"]
    $selectLabel    = $form.Controls["PackagePanel"].Controls["SelectLabel"]
    
    $selectLabel.Visible    = $false
    $installedList.Visible  = $false
    $process.Visible        = $true
    $process.Text      = "Deinstallation ausgewählter Pakete...`n`n"

    $form.Cursor = [Cursors]::AppStarting
    $selectedPackages = @($installedList.SelectedItems)
    Start-Sleep -Seconds 1
    
    foreach ($package in $selectedPackages) {
        $process.Text += "Deinstalliere $package...`n"
        choco uninstall $package -y
        Start-Sleep -Seconds 1

        $installedList.Items.Remove($package)
        $process.Text += "Abgeschlossen.`n`n"
        Start-Sleep -Seconds 1
    }

    $form.Cursor = [Cursors]::Default
    $process.Text = "Alle ausgewählten Pakete wurden deinstalliert."
    Start-Sleep -Seconds 2

    $process.Visible        = $false
    $installedList.Visible  = $true
    $installedList.ClearSelected()
    $selectLabel.Visible    = $true

    Show-MessageBox "PackagesUninstalled"
}