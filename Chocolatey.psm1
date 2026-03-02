class Chocolatey {
    [bool]$Installed
    [string]$Version
    [array]$AppList
    [System.Collections.Specialized.OrderedDictionary]$ProgramList

    # Konstruktor: Initialisiert die Klasse und aktualisiert den Installationsstatus
    Chocolatey() {         $this.ProgramList = [ordered]@{
            # Packagename bei Chocolatey | Anzeigename
            "7zip"              = "7-Zip"
            "adobereader"       = "Adobe Acrobat Reader DC"
            "autocad"           = "AutoCAD 2026"
            "autoruns"          = "Autoruns"
            "boxcryptor"        = "Boxcryptor"
            "discord"           = "Discord"
            "dropbox"           = "Dropbox"
            "filezilla"         = "FileZilla"
            "firefox"           = "Mozilla Firefox"
            "googlechrome"      = "Google Chrome"
            "googeldrive"       = "Google Drive"
            "greenshot"         = "Greenshot"
            "kate"              = "Kate"
            "keepassxc"         = "KeePassXC"
            "libreoffice-fresh" = "LibreOffic Fresh"
            "microsoft-teams"   = "Microsoft Teams (Classic Desktop App)"
            "nextcloud-client"  = "Nextcloud Desktop Client"
            "onedrive"          = "OneDrive"
            "openvpn"           = "OpenVPN"
            "openvpn-connect"   = "OpenVPN Connect"
            "qbittorrent"       = "qBittorrent"
            "pdf24"             = "PDF24 Creator"
            "putty"             = "PuTTY"
            "python3"           = "Python 3.x"
            "rustdesk"          = "RustDesk"
            "signal"            = "Signal"
            "sshfs"             = "SSHFS-Win"
            "steam"             = "Steam"
            "teamspeak"         = "TeamSpeak 3"
            "teamviewer"        = "Teamviewer"
            "teamviewer-qs"     = "Teamviewer QuickSupport"
            "thunderbird"       = "Mozilla Thunderbird"
            "ventoy"            = "Ventoy"
            "virtualbox"        = "VirtualBox"
            "visualstudio2019community" = "Visual Studio 2019 Community"
            "vlc"               = "VLC media player"
            "vscode"            = "Visual Studio Code"
            "winrar"            = "WinRAR"
            "winfsp"            = "WinFsp"
            "winscp"            = "WinSCP"
        }
        $this.Refresh()
    }

    # Aktualisiert den Installationsstatus und die Version von Chocolatey
    [void]Refresh() {
        $this.Installed = !([string]::IsNullOrWhiteSpace((Get-Command choco -ErrorAction SilentlyContinue).Source))
        $this.Version   = if( $this.Installed ) { (choco --version).Trim() } else { $null }
        $this.AppList   = if( $this.Installed ) { $this.GetAppList()       } else { @() }

    }

    # Installation & Deinstallation von Chocolatey
    [void]Install() {
        # Ausführunagsrichtlinien anpassen
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072 # Sicherheitsprotokoll anpassen
        Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -UseBasicParsing | Invoke-Expression # Chocolatey laden und installieren

        # Ersatzweise:
        # Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        $this.Refresh()
    }
    [void]Uninstall() {
        # $VerbosePreference = 'Continue'
        if (-not $env:ChocolateyInstall) {
            $message = @(
                "Umgebungsvariable ChocolateyInstall nicht gefunden."
                "Chocolatey scheinbar nicht installiert."
            ) -join "`n"

            Write-Warning $message
            return
        }

        if (-not (Test-Path $env:ChocolateyInstall)) {
            $message = @(
                "Keine Chocolatey-Installation gefunden in '$env:ChocolateyInstall'."
                "Keine Aufgaben."
            ) -join "`n"

            Write-Warning $message
            return
        }

        <#
            Using the .NET registry calls is necessary here in order to preserve environment variables embedded in PATH values;
            Powershell's registry provider doesn't provide a method of preserving variable references, and we don't want to
            accidentally overwrite them with absolute path values. Where the registry allows us to see "%SystemRoot%" in a PATH
            entry, PowerShell's registry provider only sees "C:\Windows", for example.
        #>
        $userKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
        $userPath = $userKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()

        $machineKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\ControlSet001\Control\Session Manager\Environment\', $true)
        $machinePath = $machineKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()

        $backupPATHs = @(
            "User PATH: $userPath"
            "Machine PATH: $machinePath"
        )
        $backupFile = "C:\PATH_backups_ChocolateyUninstall.txt"
        $backupPATHs | Set-Content -Path $backupFile -Encoding UTF8 -Force

        $warningMessage = @"
    This could cause issues after reboot where nothing is found if something goes wrong.
    In that case, look at the backup file for the original PATH values in '$backupFile'.
"@

        if ($userPath -like "*$env:ChocolateyInstall*") {
            Write-Verbose "Chocolatey Install location found in User Path. Removing..."
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
            Write-Verbose "Chocolatey Install location found in Machine Path. Removing..."
            Write-Warning $warningMessage

            $newMachinePATH = @(
                $machinePath -split [System.IO.Path]::PathSeparator |
                Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }
            ) -join [System.IO.Path]::PathSeparator

            # NEVER use [Environment]::SetEnvironmentVariable() for PATH values; see https://github.com/dotnet/corefx/issues/36449
            # This issue exists in ALL released versions of .NET and .NET Core as of 12/19/2019
            $machineKey.SetValue('PATH', $newMachinePATH, 'ExpandString')
        }

        # Adapt for any services running in subfolders of ChocolateyInstall
        $agentService = Get-Service -Name chocolatey-agent -ErrorAction SilentlyContinue
        if ($agentService -and $agentService.Status -eq 'Running') {
            $agentService.Stop()
        }
        # TODO: add other services here

        Remove-Item -Path $env:ChocolateyInstall -Recurse -Force

        'ChocolateyInstall', 'ChocolateyLastPathUpdate' | ForEach-Object {
            foreach ($scope in 'User', 'Machine') {
                [Environment]::SetEnvironmentVariable($_, [string]::Empty, $scope)
            }
        }

        $machineKey.Close()
        $userKey.Close()
        if ($env:ChocolateyToolsLocation -and (Test-Path $env:ChocolateyToolsLocation)) {
            Remove-Item -Path $env:ChocolateyToolsLocation -WhatIf -Recurse -Force
        }

        foreach ($scope in 'User', 'Machine') {
            [Environment]::SetEnvironmentVariable('ChocolateyToolsLocation', [string]::Empty, $scope)
        }
        $this.Refresh()
    }

    # Gibt eine Liste der installierten Programme zurück
    [array]GetAppList() {
        # Gibt eine Liste der installierten Programme zurück
        [array]$rawList = choco list --idonly
        $this.AppList = @()
        foreach ($line in $rawList) {
            if ($line -match '^\d+ packages installed\.$') {
                break
            }
            if ($line -and $line -notmatch '^Chocolatey v') {
                $this.AppList += $line.Trim()
            }
        }
        return $this.AppList
    }
}