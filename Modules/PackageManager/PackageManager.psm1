
function Get-InstalledPrograms {
    if ($script:InstalledProgramsCache) { return $script:InstalledProgramsCache }
    $appsByName = @{}

    $canReadWingetPackages = (Get-Command -Name "winget.exe" -ErrorAction SilentlyContinue) -and (Get-Command -Name "Get-WinGetPackage" -ErrorAction SilentlyContinue)
    if ($canReadWingetPackages) {
        try {
            $WinGetPrograms = @(Get-WinGetPrograms)
            foreach ($wingetApp in $WinGetPrograms) {
                if (Test-Empty $wingetApp.Name) { continue }

                $key = $wingetApp.Name.ToLowerInvariant()
                if ($appsByName.ContainsKey($key)) {
                    $version = if (Test-Empty $appsByName[$key].Version -and -not (Test-Empty $wingetApp.Version)) { $wingetApp.Version } else { $appsByName[$key].Version }
                    $appsByName[$key].WingetId  = $wingetApp.Id
                    $appsByName[$key].Source    = "$($appsByName[$key].Source), WinGet"
                    $appsByName[$key].Version   = $version
                } else {
                    $appsByName[$key] = [PSCustomObject]@{
                        Id          = $wingetApp.Id
                        Name        = $wingetApp.Name
                        Version     = $wingetApp.Version
                        Source      = $wingetApp.Source
                        WingetId    = $wingetApp.Id
                    }
                }
            }
        } catch {
            Write-Warning "WinGet-Pakete konnten nicht gelesen werden: $($_.Exception.Message)"
        }
    }

    $canReadChocolateyPackages = Get-Command -Name "choco.exe" -ErrorAction SilentlyContinue
    if ($canReadChocolateyPackages) {
        try {
            $ChocoApps = @(& choco list --limit-output --no-color 2>$null)
            
            $getChocoDisplayName = { param([string]$PackageId)
                if (Test-Empty $PackageId) { return $PackageId }

                try {
                    $packageInfo = @(& choco info $PackageId --exact --no-color 2>$null)
                    foreach ($infoLine in $packageInfo) {
                        if ($infoLine -match '^Title:\s*([^|]+?)(?:\s*\||$)') { 
                            $title = $matches[1].Trim()
                            if (Test-Fill $title) { return $title }
                        }
                    }
                } catch {}

                $prettyName = ($PackageId -split '[\.\-_]+' | Where-Object { $_ } | ForEach-Object {
                    if ($_ -cmatch '^[A-Z0-9]+$') { $_ }
                    else { (Get-Culture).TextInfo.ToTitleCase($_.ToLowerInvariant()) }
                }) -join ' '

                if (Test-Empty $prettyName) { return $PackageId }
                return $prettyName
            }

            foreach ($line in $ChocoApps) {
                if (Test-Empty $line) { continue }
                if ($line -notmatch "^[^|]+\|") { continue }

                $parts        = $line -split "\|", 2
                $chocoId      = $parts[0].Trim()
                $chocoVersion = if ($parts.Count -gt 1) { [string]$parts[1].Trim() } else { "" }
                if (Test-Empty $chocoId) { continue }
                $chocoName    = & $getChocoDisplayName $chocoId

                $key = $chocoId.ToLowerInvariant()
                if ($appsByName.ContainsKey($key)) {
                    if ($appsByName[$key].Source -notmatch "Chocolatey")                            { $appsByName[$key].Source  = "$($appsByName[$key].Source), Chocolatey" }
                    if (Test-Empty $appsByName[$key].Version -and -not (Test-Empty $chocoVersion))  { $appsByName[$key].Version = $chocoVersion }
                    if (Test-Empty $appsByName[$key].Name -or $appsByName[$key].Name -eq $chocoId)  { $appsByName[$key].Name    = $chocoName }
                    continue
                }

                $appsByName[$key] = [PSCustomObject]@{
                    Id                   = $chocoId
                    Name                 = $chocoName
                    Version              = $chocoVersion
                    Source               = "Chocolatey"
                }
            }
        } catch {
            Write-Warning "Chocolatey-Pakete konnten nicht gelesen werden: $($_.Exception.Message)"
        }
    }

    $script:InstalledProgramsCache = @($appsByName.Values | Sort-Object Name)
    return $script:InstalledProgramsCache
}

function Update-InstalledProgramsList {
    param( [System.Windows.Forms.ListView]$ListView )
    
    $ListView.BeginUpdate()
    try {
        $ListView.Items.Clear()
        $InstalledPrograms = Get-InstalledPrograms
        foreach ($program in $InstalledPrograms) { 
            $item = New-ListViewItem $program.Name @(
                [string]$(if ($program.WingetId) { $program.WingetId } else { $program.Id }),
                [string]$program.Version,
                [string]$program.Source
            )
            $item.Tag = $program
            [void]$ListView.Items.Add($item)
        }
        foreach ($column in $ListView.Columns) { $column.Width = -2 }
    } finally {
        $ListView.EndUpdate()
    }
}
function Uninstall-Program {
    param ( [System.Collections.IEnumerable]$Programs )
    $selectedPrograms = @($Programs)
    if ($selectedPrograms.Count -eq 0) { return }
    if (-not (Show-MessageBox "UninstallPackagesConfirm")) { return }

    # Starte Deinstallation mit Fortschrittsanzeige
    Show-ProgressDialog "Deinstallation" "Deinstallation wird vorbereitet..."
    try {
        foreach ($program in $selectedPrograms) {
            Update-ProgressDialog "Deinstalliere $($program.Name)..."

            # Wenn eine WingetId vorhanden ist, versuchen wir zuerst die Deinstallation über WinGet, da dies oft zuverlässiger ist und auch Apps deinstallieren kann, die nicht über die Registry erfasst werden (z.B. MS Store Apps).
            $VersionParam = if ($program.Version) { "--version `"$($program.Version)`"" } else { "" }
            if ($program.WingetId) { $command = "winget uninstall --id `"$($program.WingetId)`" --exact --source winget --accept-source-agreements --disable-interactivity $VersionParam --silent" }
            elseif ($program.Source -match "Chocolatey" -and $program.Id) { $command = "choco uninstall `"$($program.Id)`" --yes --exact --no-color --silent" }
            else { $command = "winget uninstall --id `"$($program.Id)`" --exact --source winget --accept-source-agreements --disable-interactivity $VersionParam --silent" }

            if (Test-Empty $command) {
                Update-ProgressDialog "Keine Deinstallationsroutine für $($program.Name) gefunden."
                Start-Sleep -Seconds 1
                continue
            }

            Start-Command $command
        }

        $script:InstalledProgramsCache = $null
        Close-ProgressDialog "Deinstallation abgeschlossen."
    } catch {
        Close-ProgressDialog "Deinstallation fehlgeschlagen." $_.Exception.Message
        throw
    }
}


<# WINGET #>
function Get-WinGet {
    param ( 
        [scriptblock]$ShowText = { 
            param($msg, [switch]$Final) 
            Write-Host $msg
            if ($Final) { Start-Sleep -Seconds 2 } 
        },

        $App,
        [string]$AppName,
        [string]$AppId,
        
        [PSCustomObject[]]$AppsUpdateAvailable,
        [object[]]$UninstallApps,
        $InstallApps,
        [System.Windows.Forms.ListBox]$ListBoxApps,
        
        
        [switch]$Install,
        [switch]$Installed,
        [switch]$List,
        [switch]$SetupList,
        [switch]$Uninstall,
        [switch]$Update,
        $UpdateApps,
        [switch]$UpdateAvailable,
        [switch]$Version
    )

    # WinGet-Installation, -Deinstallation, -Version, -Liste, -Updates
    if ($AppVersion) {
        $AppId = if ($App.Id) { $App.Id } else { throw "Keine gültige App-Id für die Versionsermittlung vorhanden." }
        $ver = winget show --id=$AppId --source=winget | Where-Object { $_ -match "^Version:" } | ForEach-Object { ($_ -split ":")[1].Trim() }
        return $ver
    } elseif ($AppsUpdateAvailable) {
        $IsUpdateAvailable = $false
        foreach ($app in $Apps) {
            $Id = $app.Id
            $Version = winget show --id=$($app.Id) --source=winget | Where-Object { $_ -match "^Version:" } | ForEach-Object { ($_ -split ":")[1].Trim() }
            $WinGetPackage = Get-WinGetPackage -Id $Id -Source "winget" -ErrorAction SilentlyContinue

            if ($WinGetPackage -and $WinGetPackage.IsUpdateAvailable) {
                & $ShowText "Update verfügbar für $($app.Name) (Version: $Version)"
                $IsUpdateAvailable = $true
            } else {
                & $ShowText "$($app.Name) ist auf dem neuesten Stand."
            }
        }
        return $IsUpdateAvailable
    } elseif ($Install) {
        if ($Apps -and $Apps.Count -gt 0) {
            foreach ($currentApp in $Apps) {
                & $ShowText "Installiere $($currentApp.Name)..."
                $ok = & $InstallWithMsStore -Id $currentApp.Id -Name $currentApp.Name
                if (-not $ok) { & $ShowText "Fehler: $($currentApp.Name) konnte nicht installiert werden." }
            }
            & $ShowText "Alle ausgewählten Apps wurden installiert." -Final
            return
        }

        if (Get-WinGet -Installed){ & $ShowText "$($App.Name) ist bereits installiert." -Final; return }
        & $ShowText "Starte WinGet-Installation..." 

        & $ShowText "Prüfe, ob WinGet bereits installiert ist..."
        Install-Script -Name Install-WinGet -Force -ErrorAction SilentlyContinue

        & $ShowText "Installiere WinGet..."
        winget-install --id=Install-WinGet -e --source=winget --silent

        # # Reserve
        # Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile winget.msixbundle
        # Add-AppPackage -ForceApplicationShutdown .\winget.msixbundle
        # Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.Winget.Source_8wekyb3d8bbwe
        # del .\winget.msixbundle
        # winget source reset --force
        
        & $ShowText "WinGet wurde erfolgreich installiert." -Final

        Show-MessageBox "InstallWinGetSuccess"
    } elseif ($InstallApps) {
        foreach ($app in $InstallApps) {
            & $AppInfo.DebugText "Installiere $($app.Name) (Id: $($app.Id), Version: $($app.Version))"
            & $ShowText "Installiere $($app.Name)..."
            
            try { 
                Start-Command "winget install --id=$($app.Id) --source=winget --silent"
            } catch { 
                & $ShowText "Fehler beim Installieren von $($app.Name) mit 'winget install'`: $_"
                try { 
                    Start-Command "Install-WinGetPackage -Id $($app.Id) -Silent"
                } catch { 
                    & $ShowText "Fehler beim Installieren von $($app.Name) mit 'Install-WinGetPackage'`: $_"
                }
            }
        }
        & $ShowText "Installation abgeschlossen." -Final
        return
    } elseif ($Installed) {
        $WinGetModule = Get-Module -ListAvailable -Name Microsoft.WinGet.Client
        if ($WinGetModule) { return $true } else { return $false }
    } elseif ($List) {
        if ($Setup){
            $SetupList = [ordered]@{
                "7Zip.7zip"                         = "7-Zip"
                "Bitwarden.Bitwarden"               = "Bitwarden"
                "Discord.Discord"                   = "Discord"
                "Dropbox.Dropbox"                   = "Dropbox"
                "Google.Chrome"                     = "Google Chrome"
                "Google.GoogleDrive"                = "Google Drive"
                "Greenshot.Greenshot"               = "Greenshot"
                "KDE.Kate"                          = "Kate"
                "KeePassXCTeam.KeePassXC"           = "KeePassXC"
                "TheDocumentFoundation.LibreOffice" = "LibreOffice"
                "Microsoft.Edge"                    = "Microsoft Edge"
                "9WZDNCRFJBH4"                      = "Microsoft Photos"
                "Mozilla.Firefox"                   = "Mozilla Firefox"
                "Mozilla.Thunderbird"               = "Mozilla Thunderbird"
                "Notepad++.Notepad++"               = "Notepad++"
                "SSHFS-Win.SSHFS-Win"               = "SSHFS-Win"
                "Valve.Steam"                       = "Steam"
                "TeamSpeakSystems.TeamSpeakClient"  = "TeamSpeak 3 Client"
                "Devolutions.UniGetUI"              = "UniGetUI"
                
            }
            $AppList = foreach ($key in $SetupList.Keys) {
                [PSCustomObject]@{
                    Id      = $key
                    Name    = $SetupList[$key]
                }
            }
        } else {
            $WinGetPackages = @(Get-WinGetPackage -ErrorAction SilentlyContinue | Where-Object {
                $_.Source -eq "winget" -and -not [string]::IsNullOrWhiteSpace([string]$_.Id)
            })
            $WinGetApps = foreach ($pkg in $WinGetPackages) {
                [PSCustomObject]@{
                    Id      = [string]$pkg.Id
                    Name    = [string]$pkg.Name
                    Version = if ($pkg.PSObject.Properties["InstalledVersion"] -and -not [string]::IsNullOrWhiteSpace([string]$pkg.InstalledVersion)) {
                        [string]$pkg.InstalledVersion
                    } elseif ($pkg.PSObject.Properties["Version"] -and -not [string]::IsNullOrWhiteSpace([string]$pkg.Version)) {
                        [string]$pkg.Version
                    } else {
                        ""
                    }
                }
            } 
            $AppList = $WinGetApps | Sort-Object Name
        }
        return $AppList
    } elseif ($SetupList) {
        & $AppInfo.DebugText "Funktion 'Get-WinGet -SetupList' aufgerufen. Bereite die Liste der verfügbaren Apps für die Installation vor..."
        $Items = [ordered]@{
                "7Zip.7zip"                         = "7-Zip"
                "Bitwarden.Bitwarden"               = "Bitwarden"
                "Discord.Discord"                   = "Discord"
                "Dropbox.Dropbox"                   = "Dropbox"
                "Google.Chrome"                     = "Google Chrome"
                "Google.GoogleDrive"                = "Google Drive"
                "Greenshot.Greenshot"               = "Greenshot"
                "KDE.Kate"                          = "Kate"
                "KeePassXCTeam.KeePassXC"           = "KeePassXC"
                "TheDocumentFoundation.LibreOffice" = "LibreOffice"
                "Microsoft.Edge"                    = "Microsoft Edge"
                "9WZDNCRFJBH4"                      = "Microsoft Photos"
                "Mozilla.Firefox"                   = "Mozilla Firefox"
                "Mozilla.Thunderbird"               = "Mozilla Thunderbird"
                "Notepad++.Notepad++"               = "Notepad++"
                "SSHFS-Win.SSHFS-Win"               = "SSHFS-Win"
                "Valve.Steam"                       = "Steam"
                "TeamSpeakSystems.TeamSpeakClient"  = "TeamSpeak 3 Client"
                "Devolutions.UniGetUI"              = "UniGetUI"
        }
        $AppList = foreach ($key in $Items.Keys) {
            [PSCustomObject]@{
                Id      = $key
                Name    = $Items[$key]
            }
        }
        & $AppInfo.DebugText "Rückgabewerte von Get-WinGet -SetupList: `$AppList = $($AppList | Out-String)"
        return $AppList
    } elseif ($Uninstall) {
        if(-not (Show-MessageBox "ConfirmUninstallWinGet")) { & $ShowText "Deinstallation abgebrochen." -Final; return }
        else { & $ShowText "Deinstallation von WinGet wird gestartet..." }
        $WinGetName = "Microsoft.DesktopAppInstaller"

        & $ShowText "Finde WinGet-Paketinformationen..."
        $WinGetPackage = Get-WinGetPackage -Id $WinGetName -Source "winget" -ErrorAction SilentlyContinue

        & $ShowText "Entferne WinGet-Paket..."
        Remove-AppxPackage -Package $WinGetPackage.PackageFullName -AllUsers

        & $ShowText "Entferne WinGet-ProvisionedPackage..."
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*DesktopAppInstaller*" | Remove-AppxProvisionedPackage -Online

        & $ShowText "Entferne WinGet-AppxPackage für alle Benutzer..."
        Get-AppxPackage *DesktopAppInstaller* | Remove-AppxPackage -AllUsers

        & $ShowText "WinGet wurde erfolgreich deinstalliert." -Final
        Show-MessageBox "UninstallWinGetSuccess"
        
        return
    } elseif ($UninstallApps) {
        Update-ProgressDialog "Starte Deinstallation der ausgewählten Apps..."
        foreach ($app in $UninstallApps) {
            $Id     = $app.Id
            $Name   = $app.Name

            Update-ProgressDialog "Deinstalliere $Name..."
            try { 
                Start-Command "winget uninstall --id=$Id --exact --source winget --accept-source-agreements --disable-interactivity"
            } catch { 
                & $ShowText "Fehler beim Entfernen von $Name mit 'winget uninstall'`: $_"
                try { 
                    Start-Command "Uninstall-WinGetPackage -Id $Id -Silent"
                } catch { 
                    & $ShowText "Fehler beim Entfernen von $Name mit 'Uninstall-WinGetPackage'`: $_" 
                }
            }
        }
        Close-ProgressDialog "Deinstallation abgeschlossen." -DelaySeconds 1
        return
    } elseif ($Update) {
        & $ShowText "Starte WinGet-Aktualisierung..."
        $WinGetPackage = Get-WinGetPackage -Id "Microsoft.DesktopAppInstaller" -Source "winget" -ErrorAction SilentlyContinue

        if ($WinGetPackage -and $WinGetPackage.IsUpdateAvailable) {
            & $ShowText "Update verfügbar für WinGet (Version: $($WinGetPackage.Version))"
            & $ShowText "Aktualisiere WinGet..."
            try {
                winget upgrade --id=Microsoft.DesktopAppInstaller --source=winget --silent -ErrorAction Stop
            } catch {
                & $ShowText "Fehlgeschlagen mit 'winget upgrade', versuche es mit 'Update-WinGetPackage'..."
                try {
                    Update-WinGetPackage -Id "Microsoft.DesktopAppInstaller" -Silent
                } catch {
                    & $ShowText "Fehler: WinGet konnte nicht aktualisiert werden: $_"
                }
            }
            & $ShowText "WinGet wurde erfolgreich aktualisiert." -Final
        } else {
            & $ShowText "WinGet ist bereits auf dem neuesten Stand." -Final
        }
        return
    } elseif ($UpdateApps) {
        foreach ($app in $Apps) {
            & $ShowText "Aktualisiere $($app.Name)..."
            $Id = $app.Id
            $Version = winget show --id=$($app.Id) --source=winget | Where-Object { $_ -match "^Version:" } | ForEach-Object { ($_ -split ":")[1].Trim() }

            try { & $ShowText "winget upgrade $Id"
                winget upgrade --id=$Id --exact --source winget --accept-source-agreements --disable-interactivity --version $Version --silent
            } catch { & $ShowText "Fehler beim Aktualisieren von $($app.Name) mit 'winget upgrade'`: $_"
                try { & $ShowText "Versuche es mit 'Update-WinGetPackage'..."
                    Update-WinGetPackage -Id $Id -Silent
                } catch { & $ShowText "Fehler beim Aktualisieren von $($app.Name) mit 'Update-WinGetPackage'`: $_" }
            }

            # Überprüfen, ob die Aktualisierung erfolgreich war, indem erneut nach dem Paket gesucht wird und die Version verglichen wird
            $UpdateCheck = Get-WinGetPackage -source "winget" -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq $Id }
            if ($UpdateCheck -and ($UpdateCheck.Version -ne $Version)) { & $ShowText "$($app.Name) wurde erfolgreich aktualisiert." } 
            else { & $ShowText "Fehler: $($app.Name) konnte nicht aktualisiert werden." }
        }
        & $ShowText "Alle ausgewählten Apps wurden aktualisiert." -Final
        return
    } elseif ($UpdateAvailable) {
        $WinGetPackages = Get-WinGetPackage -Source "winget" -ErrorAction SilentlyContinue
        $WinGetUpdate = $WinGetPackages | Where-Object { $_.Id -eq "Microsoft.DesktopAppInstaller" }

        if ($WinGetUpdate -and $WinGetUpdate.IsUpdateAvailable) {
            & $ShowText "Update verfügbar für WinGet (Version: $($WinGetUpdate.Version))"
            return $true
        } else {
            & $ShowText "WinGet ist auf dem neuesten Stand."
            return $false
        }
    } elseif ($Version) {
            & $ShowText "Prüfe auf installierte WinGet-Versionen..."
            # $AppVersion = (Get-WinGetVersion) -replace 'v', ''
            $modules = Get-Module -ListAvailable -Name Microsoft.WinGet.Client | Sort-Object Version -Descending
            if ($modules.Count -eq 0) {
                & $ShowText "Microsoft.WinGet.Client ist nicht installiert."
                return $null
            } elseif ($modules.Count -gt 1){

                & $ShowText "Mehrere Versionen von Microsoft.WinGet.Client gefunden. Entferne alle Versionen außer der neuesten..."
                foreach($module in $modules | Select-Object -Skip 1) { 
                    & $ShowText "Entferne Microsoft.WinGet.Client Version $($module.Version)..."
                    Uninstall-Module Microsoft.WinGet.Client -RequiredVersion $module.Version -Force 
                }
                & $ShowText "Alle älteren Versionen von Microsoft.WinGet.Client wurden entfernt."
            }
            $WinGetVersion = ($modules | Select-Object -First 1).Version.ToString()
            & $ShowText "Die installierte WinGet-Version ist: $WinGetVersion"
            return $WinGetVersion
    } else {
        & $AppLog.Info "Funktion 'Get-WinGet' aufgerufen ohne (gültige) Parameter. Überprüfe, ob WinGet installiert ist..."
        return Get-Command -Name "winget.exe" -ErrorAction SilentlyContinue
    }
}
function Get-WinGetPrograms {
    $WinGetPackages = @(Get-WinGetPackage -ErrorAction SilentlyContinue | Where-Object {
                $_.Source -eq "winget" -and -not [string]::IsNullOrWhiteSpace([string]$_.Id)
            })
            $WinGetApps = foreach ($pkg in $WinGetPackages) {
                [PSCustomObject]@{
                    Id      = [string]$pkg.Id
                    Name    = [string]$pkg.Name
                    Version = if ($pkg.PSObject.Properties["InstalledVersion"] -and -not [string]::IsNullOrWhiteSpace([string]$pkg.InstalledVersion)) {
                        [string]$pkg.InstalledVersion
                    } elseif ($pkg.PSObject.Properties["Version"] -and -not [string]::IsNullOrWhiteSpace([string]$pkg.Version)) {
                        [string]$pkg.Version
                    } else {
                        ""
                    }
                    Source = "WinGet"
                    WingetId = [string]$pkg.Id
                }
            }
            $AppList = $WinGetApps | Sort-Object Name
            return $AppList

}