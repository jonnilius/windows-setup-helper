
function Get-ChocolateyPackage {
    Write-Information "Frage nach installierten Chocolatey-Paketen..."
    $chocolateyPackages = @{
        Name    = "Keine Pakete gefunden"
        Version = ""
    }
    try {
        $chocoList = choco list --limitoutput
        $chocoPackageList = foreach ($package in $chocoList) {
            $name, $version = $package -split '\|' 
            [PSCustomObject]@{
                Name    = $name
                Version = $version
            }
        }

        $chocolateyPackages = $chocoPackageList | Sort-Object Name

    } catch { 
        # Wenn ein Fehler auftritt (z.B. Befehl nicht gefunden), wird eine leere Liste zurückgegeben
        Write-Warning "Fehler beim Abrufen der Chocolatey-Pakete: $_"
    }
    return @($chocolateyPackages)
}
function Get-SuggestedPackage {
    Write-Information "Frage nach empfohlenen Chocolatey-Paketen..."
    $suggestedPackages = [ordered]@{
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
        "firefox"                   = "Mozilla Firefox"
        "thunderbird"               = "Mozilla Thunderbird"
        "onedrive"                  = "OneDrive"
        "qbittorrent"               = "qBittorrent"
        "powerstoys"                = "PowerToys"
        "putty"                     = "PuTTY"
        "python3"                   = "Python 3.x"
        "scrcpy"                    = "scrcpy"
        "signal"                    = "Signal"
        "sshfs"                     = "SSHFS-Win"
        "steam"                     = "Steam"
        "teamspeak"                 = "TeamSpeak 3"
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
    $items = foreach ($key in $suggestedPackages.Keys) {
        [PSCustomObject]@{
            Id   = $key
            Name = $suggestedPackages[$key]
        }
    }
    return $items
}
function Get-ChocolateyVersion {
    Write-Information "Frage nach der installierten Chocolatey-Version..."
    try { 
        # Versuche die Version von Chocolatey abzurufen
        return (choco --version).Trim() 
    } catch { 
        if (
            $_.Exception -is [System.Management.Automation.CommandNotFoundException]) {
            Write-Warning "Chocolatey ist nicht installiert oder der Befehl 'choco' ist nicht verfügbar."
            return "Nicht installiert"
        } else {
            Write-Warning "Fehler beim Abrufen der Chocolatey-Version: $_"
            return "Fehler"
        }
    }
}
<##>
function Test-Chocolatey {
    Write-Information "Prüfe, ob Chocolatey installiert ist..."
    try {
        # Prüfen, ob der Befehl "choco" verfügbar ist, ohne eine Fehlermeldung auszugeben
        $CommandSource = (Get-Command choco -ErrorAction SilentlyContinue).Source
        $NullOrWhitespace = [string]::IsNullOrWhiteSpace($CommandSource)
        return -not $NullOrWhitespace
    } catch {
        # Wenn ein Fehler auftritt (z.B. Befehl nicht gefunden), wird false zurückgegeben
        Write-Warning "Fehler beim Testen von Chocolatey: $_"
        return $false
    }
}
<##>
function Uninstall-ChocolateyPackage {
    param( [string]$PackageName )
    Write-Information "Deinstalliere Chocolatey-Paket: $PackageName"
    try {
        choco uninstall $PackageName -y
        Write-Information "Paket '$PackageName' wurde erfolgreich deinstalliert."
    } catch {
        Write-Warning "Fehler beim Deinstallieren des Pakets '$PackageName': $_"
    }
}

<# Get-Chocolatey #########################################################################>
function Get-Chocolatey {
    param ( 
        [switch]$List, 
        [switch]$Test,
        [switch]$Suggested,
        [switch]$Version,
        [string]$TabName
    )
    Write-Information "Get-Chocolatey: List=$List, Test=$Test, Suggested=$Suggested, Version=$Version, TabName=$TabName"

    if ($List) { return Get-ChocolateyPackage } 
    elseif ($Test) { return Test-Chocolatey }
    elseif ($Suggested) { return Get-SuggestedPackage }
    elseif ($Version) { return Get-ChocolateyVersion }
    elseif ($TabName) { 
        switch ($TabName) {
            "PackagesTab" { return Get-ChocolateyPackage }
            "SuggestedTab" { return Get-SuggestedPackage }
            default     { return Test-Chocolatey }
        }
     }
    else { return Test-Chocolatey }
}
function Uninstall-Chocolatey {
    param( [string]$PackageName )
    
    if ($PackageName) { 
        Uninstall-ChocolateyPackage -PackageName $PackageName 
    } else { 
        Write-Warning "Kein Paketname angegeben. Bitte geben Sie den Namen des zu deinstallierenden Pakets an." 
    }
}

Export-ModuleMember -Function Get-Chocolatey, Uninstall-Chocolatey