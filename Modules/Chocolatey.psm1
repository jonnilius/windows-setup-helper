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
# Export-ModuleMember -Function Read-Chocolatey, Install-Chocolatey, Uninstall-Chocolatey

function ChocolateyForm {
    $Form = New-Form "Chocolatey"
    $PackagePanel = New-Panel "Package"
    $Form.Controls.Add($PackagePanel)

    ## Label INSTALLIERT
    $PackageLabel = New-Object System.Windows.Forms.Label
    $PackageLabel.Text = "INSTALLIERT"
    $PackageLabel.ForeColor = [ColorTranslator]::FromHtml("#EEEEEE")
    $PackageLabel.AutoSize = $true
    $PackageLabel.Location = New-Object System.Drawing.Point(10,10)
    $PackageLabel.Font = New-Object System.Drawing.Font("Consolas", 13, ([FontStyle]::Bold -bor [FontStyle]::Underline))
    $PackagePanel.Controls.Add($PackageLabel)
    $SelectAllLabel = New-Object System.Windows.Forms.Label
    ## Label ALLE AUSWÄHLEN
    $SelectAllLabel.Text = "Alle auswählen"
    $SelectAllLabel.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $SelectAllLabel.AutoSize = $true
    $SelectAllLabel.Location = New-Object System.Drawing.Point(280,10)
    $SelectAllLabel.Font = New-Object System.Drawing.Font("Consolas", 8)
    $SelectAllLabel.Cursor = [System.Windows.Forms.Cursors]::Hand
    $PackagePanel.Controls.Add($SelectAllLabel)
    $SelectAllLabel.Add_Click({
        if ($PackageList.SelectedItems.Count -eq $PackageList.Items.Count) {
            $SidebarPanel.Controls.Remove($UpdateButton)
            $SidebarPanel.Controls.Remove($UninstallButton)
            $PackageList.SelectedItems.Clear()
            $SelectAllLabel.Text = "Alle auswählen"
        } else {
            $SidebarPanel.Controls.Add($UpdateButton)
            $SidebarPanel.Controls.Add($UninstallButton)
            for ($i = 0; $i -lt $PackageList.Items.Count; $i++) {
                $PackageList.SelectedItems.Add($PackageList.Items[$i])
            }
            $SelectAllLabel.Text = "Alle abwählen"
        }
    })
    # Listbox
    $PackageList = New-ListBox "Chocolatey"
    $appList = Read-Chocolatey -AppList
    foreach ($program in $appList) { $PackageList.Items.Add($program) | Out-Null }
    $PackageList.Add_Click({
        if ($null -eq $PackageList.SelectedItem) {
            $SidebarPanel.Controls.Remove($UpdateButton)
            $SidebarPanel.Controls.Remove($UninstallButton)
        } else {
            $SidebarPanel.Controls.Add($UpdateButton)
            $SidebarPanel.Controls.Add($UninstallButton)
        }
    })
    $PackagePanel.Controls.Add($PackageList)
    # Prozess-Info
    $ProcessInfoLabel = New-Object System.Windows.Forms.Label
    $ProcessInfoLabel.Text = ""
    $ProcessInfoLabel.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $ProcessInfoLabel.Padding = New-Object System.Windows.Forms.Padding(0,5,0,10)
    $ProcessInfoLabel.Dock = "Bottom"
    $ProcessInfoLabel.Height = 30
    $ProcessInfoLabel.AutoSize = $false
    $ProcessInfoLabel.TextAlign = "MiddleCenter"
    $PackagePanel.Controls.Add($ProcessInfoLabel)

    ### Sidebar
    $SidebarPanel = New-Panel "Sidebar"
    # Version
    $VersionLabel = New-Object System.Windows.Forms.Label
    $VersionLabel.Text = "Version: $(Read-Chocolatey -Version)"
    $VersionLabel.Dock = "Top"
    $VersionLabel.ForeColor = [ColorTranslator]::FromHtml("#2D3436")
    $VersionLabel.TextAlign = "MiddleCenter"
    $VersionLabel.Font = New-Object System.Drawing.Font("Consolas", 11,[FontStyle]::Bold)
    $SidebarPanel.Controls.Add($VersionLabel)
    # Remove Button
    $RemoveButton = New-Object System.Windows.Forms.Button
    $RemoveButton.Text = "Chocolatey entfernen"
    $RemoveButton.Size = New-Object System.Drawing.Size(190,25)
    $RemoveButton.Location = New-Object System.Drawing.Point(10,35)
    $RemoveButton.FlatStyle = "Flat"
    $RemoveButton.BackColor = [ColorTranslator]::FromHtml("#2D3436")
    $RemoveButton.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $RemoveButton.Add_Click({
        $confirm = [System.Windows.Forms.MessageBox]::Show("Möchten Sie Chocolatey wirklich entfernen? Alle über Chocolatey installierten Programme müssen danach manuell deinstalliert werden.", "Bestätigung", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) { return }

        $Form.Cursor = [System.Windows.Forms.Cursors]::AppStarting

        # Chocolatey deinstallieren
        Start-Sleep -Seconds 1 # Kurze Pause, damit der Cursorwechsel sichtbar ist
        Uninstall-Chocolatey | Out-Null
        $Main.Cursor = [System.Windows.Forms.Cursors]::Default
        Start-Sleep -Seconds 1

    })
    $SidebarPanel.Controls.Add($RemoveButton)
    # Update-Button
    $UpdateButton = New-Object System.Windows.Forms.Button
    $UpdateButton.Text = "Aktualisieren"
    $UpdateButton.Size = New-Object System.Drawing.Size(190,25)
    $UpdateButton.Location = New-Object System.Drawing.Point(10,215)
    $UpdateButton.FlatStyle = "Flat"
    $UpdateButton.BackColor = [ColorTranslator]::FromHtml("#2D3436")
    $UpdateButton.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $UpdateButton.Add_Click({
        $selectedItems = @()
        $Form.Cursor = [System.Windows.Forms.Cursors]::AppStarting
        Start-Sleep -Seconds 1
        foreach ($item in $PackageList.SelectedItems) {
            $selectedItems += $item
        }
        foreach ($item in $selectedItems) {
            $ProcessInfoLabel.Text = "Aktualisiere $item..."
            choco upgrade $item -y | Out-Null
            $PackageList.Items.Remove($item)
            $PackageList.Items.Add($item) | Out-Null
        }
        $Form.Cursor = [System.Windows.Forms.Cursors]::Default
        $ProcessInfoLabel.Text = "Aktualisierung abgeschlossen."
        $PackageList.SelectedItems.Clear()
        $PackageList.Items.Clear()
        $appList = Get-ChocoAppList
        foreach ($program in $appList) { $PackageList.Items.Add($program) | Out-Null }
        $SidebarPanel.Controls.Remove($UpdateButton)
        $SidebarPanel.Controls.Remove($UninstallButton)
        $ProcessInfoLabel.Text = ""
    })
    # Uninstall-Button
    $UninstallButton = New-Object System.Windows.Forms.Button
    $UninstallButton.Text = "Deinstallieren"
    $UninstallButton.Size = New-Object System.Drawing.Size(190,25)
    $UninstallButton.Location = New-Object System.Drawing.Point(10,245)
    $UninstallButton.FlatStyle = "Flat"
    $UninstallButton.BackColor = [ColorTranslator]::FromHtml("#2D3436")
    $UninstallButton.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $UninstallButton.Add_Click({
        $selectedPackages = @()
        $Form.Cursor = [System.Windows.Forms.Cursors]::AppStarting
        Start-Sleep -Seconds 1
        foreach ($item in $PackageList.SelectedItems) {
            $selectedPackages += $item
        }
        foreach ($item in $selectedPackages) {
            $ProcessInfoLabel.Text = "Deinstalliere $item..."
            choco uninstall $item -y | Out-Null
            $PackageList.Items.Remove($item)
            $ProcessInfoLabel.Text = "Deinstallation von $item abgeschlossen."
            Start-Sleep -Seconds 1
        }
        $Form.Cursor = [System.Windows.Forms.Cursors]::Default
        $ProcessInfoLabel.Text = "Deinstallation abgeschlossen."
        $SidebarPanel.Controls.Remove($UpdateButton)
        $SidebarPanel.Controls.Remove($UninstallButton)
        $ProcessInfoLabel.Text = ""
    })

    $Form.Controls.Add($SidebarPanel)

    # Fenster anzeigen
    $Form.ShowDialog()
}