function Read-Chocolatey {
    param ( 
        [switch]$Installed,
        [switch]$Version,
        [switch]$AppList,
        [switch]$SetupList
    )
    & $AppLog.Info "Branch: Read-Chocolatey"
    
    if ($AppList)         {
        & $AppLog.Info "Key: [switch]`$AppList "

        $apkList = @()
        $rawList = choco list --idonly

        foreach ($line in $rawList) {
            if ($line -match '^\d+ packages installed\.$') { break }
            if ($line -and $line -notmatch '^Chocolatey v') { $apkList += $line.Trim() }
        }

        return $apkList
    } elseif ($Installed) { 
        & $AppLog.Info "Key: [switch]`$Installed "
        return !([string]::IsNullOrWhiteSpace((Get-Command choco -ErrorAction SilentlyContinue).Source)) 
    } elseif ($Version)   { 
        & $AppLog.Info "Key: [switch]`$Version "
        return (choco --version).Trim() 
    } elseif ($SetupList) { 
        $list = [ordered]@{
            # Packagename bei Chocolatey | Anzeigename
            "7zip"                      = "7-Zip"
            "adb"                       = "Android Debug Bridge (ADB)"
            "adobereader"               = "Adobe Acrobat Reader DC"
            "autoruns"                  = "Autoruns"
            "bitwarden"                 = "Bitwarden"
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
            "powerstoys"                = "PowerToys"
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
            "wingetui"                  = "UniGetUI"
            "ventoy"                    = "Ventoy"
            "virtualbox"                = "VirtualBox"
            "visualstudio2019buildtools"= "Visual Studio 2019 Build Tools"
            "visualstudio2019community" = "Visual Studio 2019 Community"
            "vscode"                    = "Visual Studio Code"
            "vlc"                       = "VLC media player"
            "winget"                    = "WinGet"
            "winfsp"                    = "WinFsp"
            "winrar"                    = "WinRAR"
            "winscp"                    = "WinSCP"
        }
        $items = foreach ($key in $list.Keys) {
            [PSCustomObject]@{
                Id   = $key
                Name = $list[$key]
            }
        }
        return $items
    }
}

function Install-Chocolatey {
    param ( [scriptblock]$ShowText )
    & $AppLog.Info "Branch: Install-Chocolatey"

    # Fallback-Implementierung für $ShowText, falls kein Skriptblock übergeben wurde
    if (-not $ShowText){ 
        $ShowText = { 
            param($msg, [switch]$Final) 
            Write-Host $msg
            if($Final) { Start-Sleep -Seconds 2 } 
        } 
    }
    # Ausführunagsrichtlinien anpassen (erlaubt für diesen Prozess unsignierte Skripte)
    & $ShowText "Passe Ausführungsrichtlinien an..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    
    # Sicherheitsprotokoll anpassen (benötigt für TLS 1.2, das von Chocolatey-Servern verwendet wird)
    & $ShowText "Aktualisiere Sicherheitsprotokolle für Webanfragen..."
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    
    # Chocolatey laden und installieren (Setup durch Chocolatey-Installationsskript)
    & $ShowText "Lade und installiere Chocolatey..."
    Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -UseBasicParsing | Invoke-Expression

    # Überprüfen, ob die Installation erfolgreich war
    if (Get-Chocolatey) {
        & $ShowText "Chocolatey wurde erfolgreich installiert." -Final
        Show-MessageBox "InstallChocolateySuccess"
    } else {
        & $ShowText "Fehler: Chocolatey konnte nicht installiert werden." -Final
        Show-MessageBox "InstallChocolateyFailed"
    }
}
function Uninstall-Chocolatey {
    param ( [scriptblock]$ShowText )
    & $AppLog.Info "Branch: Uninstall-Chocolatey"

    # Fallback-Implementierung für $ShowText, falls kein Skriptblock übergeben wurde
    if (-not $ShowText){ 
        $ShowText = { 
            param($msg, [switch]$Final) 
            Write-Host $msg
            if($Final) { Start-Sleep -Seconds 2 } 
        } 
    }

    # Bestätigung der Deinstallation einholen
    & $ShowText "Deinstallation von Chocolatey wird gestartet..."
    if (-not (Show-MessageBox "ConfirmUninstallChocolatey")) { 
        & $ShowText "Deinstallation von Chocolatey abgebrochen." -Final
        return 
    }

    # Umgebungsvariable für Chocolatey-Installation überprüfen
    & $ShowText "Überprüfe Chocolatey-Installation und PATH-Variablen..."
    if (-not $env:ChocolateyInstall) { 
        & $ShowText "Chocolatey ist nicht installiert oder die Umgebungsvariable fehlt." -Final
        return 
    }
    if (-not (Test-Path $env:ChocolateyInstall)) { 
        & $ShowText "Keine Chocolatey-Installation unter '$env:ChocolateyInstall' gefunden." 
        & $ShowText "Keine weitere Verarbeitung notwendig." -Final
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
    & $ShowText "Lese aktuelle PATH-Variablen aus der Registry..."
    $userKey  = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
    $userPath = $userKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()

    & $ShowText "Öffne Registry-Schlüssel für PATH-Variablen..."
    $machineKey  = [Registry]::LocalMachine.OpenSubKey('SYSTEM\ControlSet001\Control\Session Manager\Environment\', $true)
    $machinePath = $machineKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()
    
    & $ShowText "Sichere aktuelle PATH-Variablen..."
    $backupFile  = "C:\PATH_backups_ChocolateyUninstall.txt"
    $backupPATHs = @( "User PATH: $userPath", "Machine PATH: $machinePath" )
    $backupPATHs | Set-Content -Path $backupFile -Encoding UTF8 -Force

    # Chocolatey-Installationspfad aus PATH entfernen, falls vorhanden
    & $ShowText "Bereinige PATH-Variablen von Chocolatey-Installationspfad..."
    if ($userPath -like "*$env:ChocolateyInstall*") {
        & $ShowText "Chocolatey-Installationspfad im Benutzer-PATH gefunden. Wird entfernt..."

        $newUserPATH = @(
            $userPath -split [System.IO.Path]::PathSeparator |
            Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }
        ) -join [System.IO.Path]::PathSeparator

        # NEVER use [Environment]::SetEnvironmentVariable() for PATH values; see https://github.com/dotnet/corefx/issues/36449
        # This issue exists in ALL released versions of .NET and .NET Core as of 12/19/2019
        $userKey.SetValue('PATH', $newUserPATH, 'ExpandString')
    }
    if ($machinePath -like "*$env:ChocolateyInstall*") {
        & $ShowText "Chocolatey-Installationspfad im System-PATH gefunden. Wird entfernt..."

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
        & $ShowText "Stoppe Dienst: chocolatey-agent..."
        $agentService.Stop()
    }
    # TODO: Weitere relevante Dienste hier ergänzen
    & $ShowText "Lösche Chocolatey-Installationsverzeichnis..."
    Remove-Item -Path $env:ChocolateyInstall -Recurse -Force

    'ChocolateyInstall', 'ChocolateyLastPathUpdate' | ForEach-Object {
        foreach ($scope in 'User', 'Machine') { 
            [Environment]::SetEnvironmentVariable($_, [string]::Empty, $scope)
        }
    }

    & $ShowText "Schließe Registry-Schlüssel..."
    $machineKey.Close()
    $userKey.Close()
    if ($env:ChocolateyToolsLocation -and (Test-Path $env:ChocolateyToolsLocation)) {
        Remove-Item -Path $env:ChocolateyToolsLocation -Recurse -Force
    }

    foreach ($scope in 'User', 'Machine') {
        [Environment]::SetEnvironmentVariable('ChocolateyToolsLocation', [string]::Empty, $scope)
    }
    & $ShowText "Deinstallation von Chocolatey abgeschlossen." -Final
    Show-MessageBox "UninstallChocolateySuccess"
}

function InstallChocoApps {
    param ( $take )
    & $AppLog.Info "Branch: InstallChocoApps"

    $form       = $take.FindForm()
    $packagePanel= $form.Controls["PackagePanel"]
    $addTab     = $packagePanel.Controls["TabControl"].Controls["AddTab"]
    $addList    = $addTab.Controls["AddList"]
    $packagePanel.Controls["SelectLabel"].Visible = $false

    $ShowText = { param($msg, [switch]$Final) Update-Status -Label (Get-ProcessLabel $take) -Message $msg -Delay 2 -Final:$Final }

    & $ShowText "Installiere ausgewählte Pakete..."
    
    # Cursor auf "Ladevorgang" setzen und angehakete Pakete abrufen
    $form.Cursor            = [Cursors]::AppStarting
    $selectedPackages       = @($addList.CheckedItems | ForEach-Object { $_.Id })

    if ($selectedPackages.Count -eq 0) {
        $form.Cursor = [Cursors]::Default
        return
    }
    foreach ($package in $selectedPackages) {
        Start-Sleep -Seconds 1

        & $ShowText "Installiere $package..."
        choco install $package -y

        & $ShowText "Abgeschlossen."
        Start-Sleep -Seconds 1
    }

    # Installation abgeschlossen
    $form.Cursor        = [Cursors]::Default
    & $ShowText "Alle ausgewählten Pakete wurden installiert." -Final
    
    $packagePanel.Controls["SelectLabel"].Visible = $true
    $addList.ClearSelected()
    foreach ($package in $addList.CheckedIndices) {
        $addList.SetItemChecked($package, $false)
    }
    Show-MessageBox "PackagesInstallSuccess"
}
function UpdateChocoApps {
    param ( $take )
    & $AppLog.Info "Branch: UpdateChocoApps"

    $form           = $take.FindForm()
    $packagePanel   = $form.Controls["PackagePanel"]
    $manageTab      = $packagePanel.Controls["TabControl"].Controls["ManageTab"]
    $installedList  = $manageTab.Controls["InstalledList"]

    $ShowText = { param($msg, [switch]$Final) Update-Status -Label (Get-ProcessLabel $take) -Message $msg -Delay 2 -Final:$Final }

    # Prozesslabel für Statusinformationen abrufen und initialisieren
    & $ShowText "Aktualisiere ausgewählte Pakete..."
    
    # Cursor auf "Ladevorgang" setzen und ausgewählte Pakete abrufen
    
    $selectedPackages       = $installedList.SelectedItems | ForEach-Object { $_.Name }
    Start-Sleep -Seconds 1

    foreach ($package in $selectedPackages) {
        & $ShowText "Aktualisiere $package..."
        choco upgrade $package -y
    }

    # Aktualisierung abgeschlossen
    & $ShowText "Alle ausgewählten Pakete wurden aktualisiert." -Final
    
    $installedList.ClearSelected()
    Show-MessageBox "PackagesUpdateSuccess"
}
function UninstallChocoApps {
    param ($take)
    & $AppLog.Info "Branch: UninstallChocoApps"

    $form           = $take.FindForm()
    $packagePanel   = $form.Controls["PackagePanel"]
    $manageTab      = $packagePanel.Controls["TabControl"].Controls["ManageTab"]
    $installedList  = $manageTab.Controls["InstalledList"]
    $selectLabel    = $packagePanel.Controls["SelectLabel"]

    $ShowText = { param($msg, [switch]$Final) Update-Status -Label (Get-ProcessLabel $take) -Message $msg -Delay 2 -Final:$Final }
    
    $selectLabel.Visible    = $false
    & $ShowText "Deinstallation ausgewählter Pakete..."

    $form.Cursor = [Cursors]::AppStarting
    $selectedPackages = @($installedList.SelectedItems)
    Start-Sleep -Seconds 1
    
    foreach ($package in $selectedPackages) {
        & $ShowText "Deinstalliere $package..."
        choco uninstall $package -y
        Start-Sleep -Seconds 1

        $installedList.Items.Remove($package)
        & $ShowText "Abgeschlossen."
        Start-Sleep -Seconds 1
    }

    $form.Cursor = [Cursors]::Default
    & $ShowText "Alle ausgewählten Pakete wurden deinstalliert." -Final
    Start-Sleep -Seconds 2

    $installedList.ClearSelected()
    $selectLabel.Visible    = $true

    Show-MessageBox "PackagesUninstallSuccess"
}