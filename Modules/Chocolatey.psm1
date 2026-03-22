function Read-Chocolatey {
    param ( 
        [switch]$Installed,
        [switch]$Version,
        [switch]$AppList,
        [switch]$SetupList
    )
    
    if ($AppList)         {
        & $AppInfo.DebugText "Funktion 'Read-Chocolatey -AppList' aufgerufen. Lade Liste der installierten Pakete..."

        $apkList = @()
        $rawList = choco list --idonly

        foreach ($line in $rawList) {
            if ($line -match '^\d+ packages installed\.$') { break }
            if ($line -and $line -notmatch '^Chocolatey v') { $apkList += $line.Trim() }
        }

        return $apkList
    } elseif ($Installed) { 
        & $AppInfo.DebugText "Funktion 'Read-Chocolatey -Installed' aufgerufen. Überprüfe, ob Chocolatey installiert ist..."
        return !([string]::IsNullOrWhiteSpace((Get-Command choco -ErrorAction SilentlyContinue).Source)) 
    } elseif ($Version)   { 
        & $AppInfo.DebugText "Funktion 'Read-Chocolatey -Version' aufgerufen. Lade die installierte Version von Chocolatey..."
        return (choco --version).Trim() 
    } elseif ($SetupList) { 
        # & $AppInfo.DebugText "Funktion 'Read-Chocolatey -SetupList' aufgerufen. Bereite die Liste der verfügbaren Pakete für die Installation vor..."
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
        # & $AppInfo.DebugText "Rückgabewerte von Get-Chocolatey -SetupList: $($items | Out-String)"
        return $items
    }
}
function Get-Chocolatey {
    & $AppInfo.DebugText "Funktion 'Get-Chocolatey' aufgerufen. Überprüfe, ob Chocolatey installiert ist..."
    return !([string]::IsNullOrWhiteSpace((Get-Command choco -ErrorAction SilentlyContinue).Source))
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
    param ( [scriptblock]$ShowText )
    if (-not $ShowText){ $ShowText = { param($msg, [switch]$Final) Write-Host $msg; if($Final) { Start-Sleep -Seconds 2 } } }

    # Bestätigung der Deinstallation einholen
    if (-not (Show-MessageBox "ConfirmUninstallChocolatey")) { & $ShowText "Deinstallation von Chocolatey abgebrochen." -Final; return }

    # Umgebungsvariable für Chocolatey-Installation überprüfen
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
    $userKey  = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
    $userPath = $userKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()

    $machineKey  = [Registry]::LocalMachine.OpenSubKey('SYSTEM\ControlSet001\Control\Session Manager\Environment\', $true)
    $machinePath = $machineKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()
    
    $backupFile  = "C:\PATH_backups_ChocolateyUninstall.txt"
    $backupPATHs = @( "User PATH: $userPath", "Machine PATH: $machinePath" )
    $backupPATHs | Set-Content -Path $backupFile -Encoding UTF8 -Force

    # Chocolatey-Installationspfad aus PATH entfernen, falls vorhanden
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

    $packagePanel= $form.Controls["PackagePanel"]
    $addTab     = $packagePanel.Controls["TabControl"].Controls["AddTab"]
    $addList    = $addTab.Controls["AddList"]
    $process    = $addTab.Controls["Process"]
    $packagePanel.Controls["SelectLabel"].Visible = $false

    $ShowText = { param($msg, [switch]$Final) Update-Status -Label $process -Message $msg -Delay 2 -Final:$Final }

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
    Show-MessageBox "PackagesInstalled"
}
function UpdateChocoApps {
    param ( $form )

    $packagePanel    = $form.Controls["PackagePanel"]
    $manageTab       = $packagePanel.Controls["TabControl"].Controls["ManageTab"]
    $installedList   = $manageTab.Controls["InstalledList"]
    $process         = $manageTab.Controls["Process"]

    $ShowText = { param($msg, [switch]$Final) Update-Status -Label $process -Message $msg -Delay 2 -Final:$Final }

    # Prozesslabel für Statusinformationen abrufen und initialisieren
    & $ShowText "Aktualisiere ausgewählte Pakete..."
    
    # Cursor auf "Ladevorgang" setzen und ausgewählte Pakete abrufen
    $form.Cursor            = [Cursors]::AppStarting
    $selectedPackages       = @($installedList.SelectedItems)
    Start-Sleep -Seconds 1

    foreach ($package in $selectedPackages) {
        & $ShowText "Aktualisiere $package..."
        Start-Sleep -Seconds 1
        choco upgrade $package -y
        & $ShowText "Abgeschlossen."
        Start-Sleep -Seconds 1
    }

    # Aktualisierung abgeschlossen
    $form.Cursor        = [Cursors]::Default
    & $ShowText "Alle ausgewählten Pakete wurden aktualisiert." -Final
    
    $installedList.ClearSelected()
    Show-MessageBox "PackagesUpdated"
}
function UninstallChocoApps {
    param ($form)

    $packagePanel    = $form.Controls["PackagePanel"]
    $manageTab       = $packagePanel.Controls["TabControl"].Controls["ManageTab"]
    $installedList   = $manageTab.Controls["InstalledList"]
    $process         = $manageTab.Controls["Process"]
    $selectLabel     = $packagePanel.Controls["SelectLabel"]

    $ShowText = { param($msg, [switch]$Final) Update-Status -Label $process -Message $msg -Delay 2 -Final:$Final }
    
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

    Show-MessageBox "PackagesUninstalled"
}