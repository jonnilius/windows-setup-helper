using namespace Microsoft.Win32

$script:Installed           = !([string]::IsNullOrWhiteSpace((Get-Command choco -ErrorAction SilentlyContinue).Source))
$script:Version             = if( $Installed ) { (choco --version).Trim() } else { $null }
$script:ChocoSetupList      = [ordered]@{
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
function Get-ChocoInstalled     { return $script:Installed }
function Get-ChocoSetupList     { return $script:ChocoSetupList }
function Get-ChocoVersion       { return $script:Version }
function Get-ChocoAppList       {
    # Gibt eine Auflistung der installierten Programme zurück
    $appList = @()
    $rawList = choco list --idonly

    # Ausgabe filtern, um nur die Paketnamen zu erhalten
    foreach ($line in $rawList) {
        if ($line -match '^\d+ packages installed\.$') { break }
        if ($line -and $line -notmatch '^Chocolatey v') { $appList += $line.Trim() }
    }

    return $appList
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

Export-ModuleMember -Function Get-ChocoInstalled,
    Get-ChocoVersion, 
    Get-ChocoSetupList, 
    Get-ChocoAppList, 
    Install-Chocolatey, 
    Uninstall-Chocolatey
