
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


Export-ModuleMember -Function Get-Chocolatey