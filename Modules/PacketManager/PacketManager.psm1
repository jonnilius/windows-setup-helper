<# APPLICATION #>
function Install-Application {
    param( [string]$Name, [string]$Manager )
    
    if ($Manager -eq "Choco") { $Manager = "Chocolatey" }
    switch ($Manager) {
        "Chocolatey" { 
            Write-Information "Installiere Chocolatey-Paket: $Name"
            try {
                choco install $Name -y
                Write-Information "Paket '$Name' wurde erfolgreich installiert."
            } catch {
                Write-Warning "Fehler beim Installieren des Pakets '$Name': $_"
            }
        }
        default { 
            Write-Warning "Unbekannter Paketmanager: $Manager. Bitte geben Sie einen gültigen Paketmanager an (z.B. 'Chocolatey')."
        }
    }
}
function Uninstall-Application {
    param( [string]$Name, [string]$Manager )
    $Manager = if ($Manager -eq "Choco") { "Chocolatey" } else { $Manager }
    
    switch ($Manager) {
        "Chocolatey" { 
            Write-Information "Deinstalliere Chocolatey-Paket: $Name"
            try {
                choco uninstall $Name -y
                Write-Information "Paket '$Name' wurde erfolgreich deinstalliert."
            } catch {
                Write-Warning "Fehler beim Deinstallieren des Pakets '$Name': $_"
            }
        }
        default { 
            Write-Warning "Unbekannter Paketmanager: $Manager. Bitte geben Sie einen gültigen Paketmanager an (z.B. 'Chocolatey')."
        }
    }
}
function Search-Application {
    param(
        [string]$Query,
        [string]$Manager,
        [string]$SearchToken,
        [System.Windows.Forms.TextBox]$SearchBox,
        [int]$SearchDurationMs = 12000
    )
    $Manager = if ($Manager -eq "Choco") { "Chocolatey" } else { $Manager }
    
    switch ($Manager) {
        "Chocolatey" { 
            Write-Information "Suche nach Chocolatey-Paketen mit Query: $Query"
            try {
                $startedAt = [System.DateTime]::UtcNow
                $psi = [System.Diagnostics.ProcessStartInfo]::new()
                $psi.FileName = (Get-Command choco -ErrorAction Stop).Source
                $psi.Arguments = "search `"$Query`" --limit-output"
                $psi.UseShellExecute = $false
                $psi.CreateNoWindow = $true
                $psi.RedirectStandardOutput = $true
                $psi.RedirectStandardError = $true

                $process = [System.Diagnostics.Process]::new()
                $process.StartInfo = $psi
                [void]$process.Start()

                while (-not $process.HasExited) {
                    Start-Sleep -Milliseconds 60
                    if ("System.Windows.Forms.Application" -as [type]) {
                        [System.Windows.Forms.Application]::DoEvents()
                    }

                    $elapsedMs = [int]([System.DateTime]::UtcNow - $startedAt).TotalMilliseconds
                    if ($elapsedMs -ge $SearchDurationMs) {
                        $process.Kill()
                        [void]$process.WaitForExit(500)
                        Write-Warning "Suche nach '$Query' wurde nach $SearchDurationMs ms beendet (Timeout)."
                        return @()
                    }

                    if ($SearchBox -and -not $SearchBox.IsDisposed -and $SearchBox.Text.Trim() -ne $Query) {
                        $process.Kill()
                        [void]$process.WaitForExit(500)
                        return @()
                    }
                }

                $stdOut = $process.StandardOutput.ReadToEnd()
                $stdErr = $process.StandardError.ReadToEnd()
                $lines = @($stdOut -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
                $results = foreach ($line in $lines) {
                    if ($line -match '^([^|]+)\|(.+)$') {
                        $id = $matches[1].Trim()
                        $version = $matches[2].Trim()
                        $cachedDetails = Get-ApplicationDetailsFromCache -Name $id -Manager $Manager
                        if ($cachedDetails) {
                            $cachedDetails.Version = if ([string]::IsNullOrWhiteSpace($cachedDetails.Version)) { $version } else { $cachedDetails.Version }
                            $cachedDetails.DisplayName = Get-ApplicationDisplayName -Package $cachedDetails
                            $cachedDetails
                            continue
                        }

                        [PSCustomObject]@{
                            Id          = $id
                            Name        = $id
                            Version     = $version
                            Title       = ""
                            DisplayName = (Get-ApplicationDisplayName -Package ([PSCustomObject]@{ Id = $id; Name = $id; Version = $version; Title = "" }))
                            Raw         = $line
                        }
                    }
                }

                if (-not [string]::IsNullOrWhiteSpace($stdErr)) { Write-Warning "Chocolatey-Suche meldet Fehler: $stdErr" }

                if ($results) {
                    Write-Information "Gefundene Pakete:"
                    $results | ForEach-Object { Write-Information $_ }
                    return $results
                } else {
                    Write-Information "Keine Pakete gefunden, die '$Query' entsprechen."
                    return @()
                }
            } catch {
                Write-Warning "Fehler bei der Suche nach Paketen mit Query '$Query': $_"
            }
        }
        default { 
            Write-Warning "Unbekannter Paketmanager: $Manager. Bitte geben Sie einen gültigen Paketmanager an (z.B. 'Chocolatey')."
        }
    }
}
function Test-Application {
    param( [string]$Name, [string]$Manager )
    $Manager = if ($Manager -eq "Choco") { "Chocolatey" } else { $Manager }
    
    switch ($Manager) {
        "Chocolatey" { 
            Write-Information "Teste, ob Chocolatey-Paket installiert ist: $Name"
            try {
                $result = choco list --local-only --exact $Name
                return -not [string]::IsNullOrWhiteSpace($result) -and $result -match "^$Name\|"
            } catch {
                Write-Warning "Fehler beim Testen des Pakets '$Name': $_"
                return $false
            }
        }
        default { 
            Write-Warning "Unbekannter Paketmanager: $Manager. Bitte geben Sie einen gültigen Paketmanager an (z.B. 'Chocolatey')."
            return $false
        }
    }
}
function Update-Application {
    param( [string]$Name, [string]$Manager )
    $Manager = if ($Manager -eq "Choco") { "Chocolatey" } else { $Manager }
    
    switch ($Manager) {
        "Chocolatey" { 
            Write-Information "Aktualisiere Chocolatey-Paket: $Name"
            try {
                choco upgrade $Name -y
                Write-Information "Paket '$Name' wurde erfolgreich aktualisiert."
            } catch {
                Write-Warning "Fehler beim Aktualisieren des Pakets '$Name': $_"
            }
        }
        default { 
            Write-Warning "Unbekannter Paketmanager: $Manager. Bitte geben Sie einen gültigen Paketmanager an (z.B. 'Chocolatey')."
        }
    }
}


function Get-InstalledApplications {
    param( [string]$Manager )

    $Manager = if ($Manager -eq "Choco") { "Chocolatey" } else { $Manager }
    switch ($Manager) {
        "Chocolatey" { 
            Write-Information "Hole Liste aller lokal installierten Chocolatey-Pakete..."
            try {
                $result = choco list --local-only --limit-output
                $packages = @()
                foreach ($line in ($result -split "`r?`n")) {
                    if ($line -match '^([^|]+)\|(.+)$') {
                        $id = $matches[1].Trim()
                        $version = $matches[2].Trim()
                        $packages += [PSCustomObject]@{
                            Id      = $id
                            Name    = $id
                            Version = $version
                        }
                    }
                }
                Write-Information "Gefundene installierte Pakete: $($packages.Count)"
                return $packages
            } catch {
                Write-Warning "Fehler beim Abrufen der installierten Pakete: $_"
                return @()
            }
        }
        "Winget" {
            Write-Information "Hole Liste aller lokal installierten Winget-Pakete..."
            try {
                $result = winget list --source winget --accept-source-agreements --accept-package-agreements
                $packages = @()
                foreach ($line in ($result -split "`r?`n")) {
                    if ($line -match '^([^|]+)\|([^|]+)\|(.+)$') {
                        $id = $matches[1].Trim()
                        $name = $matches[2].Trim()
                        $version = $matches[3].Trim()
                        $packages += [PSCustomObject]@{
                            Id      = $id
                            Name    = $name
                            Version = $version
                        }
                    }
                }
                Write-Information "Gefundene installierte Pakete: $($packages.Count)"
                return $packages
            } catch {
                Write-Warning "Fehler beim Abrufen der installierten Pakete: $_"
                return @()
            }
        }
        default { 
            Write-Information "Hole Liste aller installierten Anwendungen"
            $result = Get-WinGetPackage -Source "winget" -Verbose
            if ($result) {
                $packages = foreach ($pkg in $result) {
                    [PSCustomObject]@{
                        Id      = $pkg.Id
                        Name    = $pkg.Name
                        Version = if($pkg.Version) { $pkg.Version.ToString() } else { $pkg.InstalledVersion.ToString() }
                    }
                }
                Write-Information "Gefundene installierte Pakete: $($packages.Count)"
                return $packages
            } else {
                Write-Information "Keine installierten Pakete gefunden."
                return @()
            }
        }
    }
}


<## APPLICATION-DETAILS ##>
if (-not $script:ApplicationDetailsCache) { $script:ApplicationDetailsCache = @{} }
function Get-ApplicationDetails {
    param(
        [string]$Name,
        [string]$Manager,
        [int]$SearchDurationMs = 8000
    )

    $Manager = if ($Manager -eq "Choco") { "Chocolatey" } else { $Manager }

    switch ($Manager) {
        "Chocolatey" {
            try {
                $psi = [System.Diagnostics.ProcessStartInfo]::new()
                $psi.FileName = (Get-Command choco -ErrorAction Stop).Source
                $psi.Arguments = "info `"$Name`""
                $psi.UseShellExecute = $false
                $psi.CreateNoWindow = $true
                $psi.RedirectStandardOutput = $true
                $psi.RedirectStandardError = $true

                $process = [System.Diagnostics.Process]::new()
                $process.StartInfo = $psi
                [void]$process.Start()

                $startedAt = [System.DateTime]::UtcNow
                while (-not $process.HasExited) {
                    Start-Sleep -Milliseconds 60
                    if ("System.Windows.Forms.Application" -as [type]) {
                        [System.Windows.Forms.Application]::DoEvents()
                    }

                    $elapsedMs = [int]([System.DateTime]::UtcNow - $startedAt).TotalMilliseconds
                    if ($elapsedMs -ge $SearchDurationMs) {
                        $process.Kill()
                        [void]$process.WaitForExit(500)
                        return $null
                    }
                }

                $stdOut = $process.StandardOutput.ReadToEnd()
                $stdErr = $process.StandardError.ReadToEnd()
                if (-not [string]::IsNullOrWhiteSpace($stdErr)) {
                    Write-Warning "Fehler beim Laden von Paketdetails fuer '$Name': $stdErr"
                }

                $details = ConvertFrom-ChocolateyInfoText -Text $stdOut -Name $Name
                $script:ApplicationDetailsCache["$Manager::$Name"] = $details
                return $details
            } catch {
                Write-Warning "Fehler beim Abrufen der Paketdetails fuer '$Name': $_"
                return $null
            }
        }
        default {
            Write-Warning "Unbekannter Paketmanager: $Manager. Bitte geben Sie einen gueltigen Paketmanager an (z.B. 'Chocolatey')."
            return $null
        }
    }
}
function Get-ApplicationDisplayName {
    param($Package)

    if ($null -eq $Package) {
        return ""
    }

    $versionText = if ([string]::IsNullOrWhiteSpace($Package.Version)) {
        ""
    } else {
        " v$($Package.Version)"
    }

    if (-not [string]::IsNullOrWhiteSpace($Package.Title)) {
        return "$($Package.Title)$versionText"
    }

    if (-not [string]::IsNullOrWhiteSpace($Package.Name)) {
        return "$($Package.Name)$versionText"
    }

    return "$($Package.Id)$versionText"
}
function Get-ApplicationDetailsFromCache {
    param(
        [string]$Name,
        [string]$Manager
    )

    $cacheKey = "$Manager::$Name"
    if ($script:ApplicationDetailsCache.ContainsKey($cacheKey)) {
        return $script:ApplicationDetailsCache[$cacheKey]
    }

    return $null
}

function Get-CachedApplicationDetails {
    param(
        [string]$Name,
        [string]$Manager,
        [int]$SearchDurationMs = 8000,
        [string]$FallbackVersion = "",
        [switch]$Refresh
    )

    $cacheKey = "$Manager::$Name"
    if (-not $Refresh -and $script:ApplicationDetailsCache.ContainsKey($cacheKey)) {
        return $script:ApplicationDetailsCache[$cacheKey]
    }

    $details = Get-ApplicationDetails -Name $Name -Manager $Manager -SearchDurationMs $SearchDurationMs
    if ($details) {
        if ([string]::IsNullOrWhiteSpace($details.Version) -and -not [string]::IsNullOrWhiteSpace($FallbackVersion)) {
            $details.Version = $FallbackVersion
        }
        $details.DisplayName = Get-ApplicationDisplayName -Package $details
        $script:ApplicationDetailsCache[$cacheKey] = $details
    }

    return $details
}
function Set-CachedApplicationDetails {
    param(
        [string]$Name,
        [string]$Manager,
        $Details
    )

    if ($null -eq $Details) {
        return $null
    }

    $cacheKey = "$Manager::$Name"
    $script:ApplicationDetailsCache[$cacheKey] = $Details
    return $Details
}

<# CHOCOLATEY #>
function Install-Chocolatey {
    Write-Information "Starte Installation von Chocolatey..."

    # Ausführunagsrichtlinien anpassen (erlaubt für diesen Prozess unsignierte Skripte)
    Write-Information "Setze Ausführungsrichtlinie auf Bypass für diesen Prozess..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    
    # Sicherheitsprotokoll anpassen (benötigt für TLS 1.2, das von Chocolatey-Servern verwendet wird)
    Write-Information "Aktualisiere Sicherheitsprotokolle für Webanfragen..."
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    
    # Chocolatey laden und installieren (Setup durch Chocolatey-Installationsskript)
    Write-Information "Lade und installiere Chocolatey..."
    Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -UseBasicParsing | Invoke-Expression

    # Überprüfen, ob die Installation erfolgreich war
    if (Get-Chocolatey) {
        Write-Information "Chocolatey wurde erfolgreich installiert."
        Show-MessageBox "InstallChocolateySuccess"
    } else {
        Write-Warning "Fehler: Chocolatey konnte nicht installiert werden."
        Show-MessageBox "InstallChocolateyFailed"
    }
}
function Uninstall-Chocolatey {
    # Bestätigung der Deinstallation einholen
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Möchten Sie Chocolatey wirklich deinstallieren? Alle über Chocolatey installierten Pakete müssen danach manuell entfernt werden.",
        "Deinstallation von Chocolatey bestätigen",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-Information "Deinstallation von Chocolatey abgebrochen."
        return 
    }

    # Umgebungsvariable für Chocolatey-Installation überprüfen
    Write-Information "Überprüfe Chocolatey-Installation und PATH-Variablen..."
    if (-not $env:ChocolateyInstall) { 
        Write-Information "Chocolatey ist nicht installiert oder die Umgebungsvariable fehlt."
        return 
    }
    if (-not (Test-Path $env:ChocolateyInstall)) { 
        Write-Information "Keine Chocolatey-Installation unter '$env:ChocolateyInstall' gefunden."
        Write-Information "Keine weitere Verarbeitung notwendig."
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
    Write-Information "Lese aktuelle PATH-Variablen aus der Registry..."
    $userKey  = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
    $userPath = $userKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()

    Write-Information "Öffne Registry-Schlüssel für PATH-Variablen..."
    $machineKey  = [Registry]::LocalMachine.OpenSubKey('SYSTEM\ControlSet001\Control\Session Manager\Environment\', $true)
    $machinePath = $machineKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()
    
    Write-Information "Sichere aktuelle PATH-Variablen..."
    $backupFile  = "C:\PATH_backups_ChocolateyUninstall.txt"
    $backupPATHs = @( "User PATH: $userPath", "Machine PATH: $machinePath" )
    $backupPATHs | Set-Content -Path $backupFile -Encoding UTF8 -Force

    # Chocolatey-Installationspfad aus PATH entfernen, falls vorhanden
    Write-Information "Bereinige PATH-Variablen von Chocolatey-Installationspfad..."
    if ($userPath -like "*$env:ChocolateyInstall*") {
        Write-Information "Chocolatey-Installationspfad im Benutzer-PATH gefunden. Wird entfernt..."

        $newUserPATH = @(
            $userPath -split [System.IO.Path]::PathSeparator |
            Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }
        ) -join [System.IO.Path]::PathSeparator

        # NEVER use [Environment]::SetEnvironmentVariable() for PATH values; see https://github.com/dotnet/corefx/issues/36449
        # This issue exists in ALL released versions of .NET and .NET Core as of 12/19/2019
        $userKey.SetValue('PATH', $newUserPATH, 'ExpandString')
    }
    if ($machinePath -like "*$env:ChocolateyInstall*") {
        Write-Information "Chocolatey-Installationspfad im System-PATH gefunden. Wird entfernt..."

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
        Write-Information "Stoppe Dienst: chocolatey-agent..."
        $agentService.Stop()
    }
    # TODO: Weitere relevante Dienste hier ergänzen
    Write-Information "Lösche Chocolatey-Installationsverzeichnis..."
    Remove-Item -Path $env:ChocolateyInstall -Recurse -Force

    'ChocolateyInstall', 'ChocolateyLastPathUpdate' | ForEach-Object {
        foreach ($scope in 'User', 'Machine') { 
            [Environment]::SetEnvironmentVariable($_, [string]::Empty, $scope)
        }
    }

    Write-Information "Schließe Registry-Schlüssel..."
    $machineKey.Close()
    $userKey.Close()
    if ($env:ChocolateyToolsLocation -and (Test-Path $env:ChocolateyToolsLocation)) {
        Remove-Item -Path $env:ChocolateyToolsLocation -Recurse -Force
    }

    foreach ($scope in 'User', 'Machine') {
        [Environment]::SetEnvironmentVariable('ChocolateyToolsLocation', [string]::Empty, $scope)
    }
    Write-Information "Deinstallation von Chocolatey abgeschlossen."

    # Mitteilung an den Benutzer abschließen
    [System.Windows.Forms.MessageBox]::Show(
        "Chocolatey wurde erfolgreich deinstalliert. Alle über Chocolatey installierten Pakete müssen manuell entfernt werden. Es wird empfohlen, die gesicherten PATH-Variablen in 'C:\PATH_backups_ChocolateyUninstall.txt' zu überprüfen und ggf. wiederherzustellen.",
        "Deinstallation von Chocolatey abgeschlossen",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}
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
function ConvertFrom-ChocolateyInfoText {
    param(
        [string]$Text,
        [string]$Name,
        [string]$FallbackVersion = ""
    )

    $details = [ordered]@{
        Id           = $Name
        Name         = $Name
        Version      = $FallbackVersion
        Title        = ""
        Published    = ""
        Authors      = ""
        Tags         = ""
        Summary      = ""
        Description  = ""
        SoftwareSite = ""
        DisplayName  = if ([string]::IsNullOrWhiteSpace($FallbackVersion)) { $Name } else { "$Name v$FallbackVersion" }
    }

    $descriptionLines = @()
    $inDescription = $false

    foreach ($line in ($Text -split "`r?`n")) {
        $trimmed = $line.Trim()

        if ($inDescription) {
            if ($line -match '^\s*[A-Za-z][A-Za-z\s-]+:\s*') {
                $inDescription = $false
            } elseif (-not [string]::IsNullOrWhiteSpace($trimmed)) {
                $descriptionLines += $trimmed
                continue
            } else {
                continue
            }
        }

        if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }

        if ($trimmed -match '^([^\s]+)\s+([^\s]+)\s+\[.*\]$' -and [string]::IsNullOrWhiteSpace($details.Version)) {
            $details.Id = $matches[1].Trim()
            $details.Name = $details.Id
            $details.Version = $matches[2].Trim()
            continue
        }

        if ($trimmed -match '^Title:\s*([^|]+?)(?:\s*\|\s*Published:\s*(.+))?$') {
            $details.Title = $matches[1].Trim()
            if ($matches[2]) {
                $details.Published = $matches[2].Trim()
            }
            continue
        }
        if ($trimmed -match '^Tags:\s*(.+)$') { $details.Tags = $matches[1].Trim(); continue }
        if ($trimmed -match '^Authors:\s*(.+)$') { $details.Authors = $matches[1].Trim(); continue }
        if ($trimmed -match '^Summary:\s*(.+)$') { $details.Summary = $matches[1].Trim(); continue }
        if ($trimmed -match '^Description:\s*(.*)$') {
            if (-not [string]::IsNullOrWhiteSpace($matches[1])) {
                $descriptionLines += $matches[1].Trim()
            }
            $inDescription = $true
            continue
        }
        if ($trimmed -match '^Software Site:\s*(.+)$') { $details.SoftwareSite = $matches[1].Trim(); continue }
    }

    if ($descriptionLines.Count -gt 0) {
        $details.Description = ($descriptionLines -join "`n")
    }

    $details.DisplayName = Get-ApplicationDisplayName -Package ([PSCustomObject]$details)
    return [PSCustomObject]$details
}
function Stop-ChocolateySearchTitleEnrichment {
    param([System.Windows.Forms.TextBox]$SearchBox)

    if ($null -eq $SearchBox -or $SearchBox.IsDisposed) {
        return
    }

    if (-not ($SearchBox.Tag -is [hashtable])) {
        return
    }

    if ($SearchBox.Tag.ContainsKey("TitleEnrichmentTimer") -and $SearchBox.Tag.TitleEnrichmentTimer) {
        $SearchBox.Tag.TitleEnrichmentTimer.Stop()
        $SearchBox.Tag.TitleEnrichmentTimer.Dispose()
        $SearchBox.Tag.TitleEnrichmentTimer = $null
    }

    if ($SearchBox.Tag.ContainsKey("TitleLookup") -and $SearchBox.Tag.TitleLookup) {
        $lookup = $SearchBox.Tag.TitleLookup
        if ($lookup.Process) {
            try {
                if (-not $lookup.Process.HasExited) {
                    $lookup.Process.Kill()
                    [void]$lookup.Process.WaitForExit(500)
                }
            } catch {
            } finally {
                $lookup.Process.Dispose()
            }
        }
        $SearchBox.Tag.TitleLookup = $null
    }
}

function Set-SearchInfoLabelText {
    param(
        [System.Windows.Forms.Label]$Label,
        [string[]]$Lines = @(),
        [string]$Description = "",
        [int]$DescriptionMaxLength = 320
    )

    $baseText = ($Lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`n"
    $Label.Tag = $null
    $Label.Cursor = [Cursors]::Default

    if ([string]::IsNullOrWhiteSpace($Description)) {
        $Label.Text = $baseText
        return
    }

    $fullText = if ([string]::IsNullOrWhiteSpace($baseText)) {
        "Beschreibung:`n$Description"
    } else {
        "$baseText`nBeschreibung:`n$Description"
    }

    if ($Description.Length -le $DescriptionMaxLength) {
        $Label.Text = $fullText
        return
    }

    $shortDescription = $Description.Substring(0, $DescriptionMaxLength)
    $lastWordBoundary = $shortDescription.LastIndexOf(' ')
    if ($lastWordBoundary -gt 0) {
        $shortDescription = $shortDescription.Substring(0, $lastWordBoundary)
    }

    $collapsedText = if ([string]::IsNullOrWhiteSpace($baseText)) {
        "Beschreibung:`n$shortDescription...`n`n[Klicken zum Ausklappen]"
    } else {
        "$baseText`nBeschreibung:`n$shortDescription...`n`n[Klicken zum Ausklappen]"
    }
    $expandedText = "$fullText`n`n[Klicken zum Einklappen]"

    $Label.Tag = @{
        ToggleEnabled = $true
        Expanded = $false
        CollapsedText = $collapsedText
        ExpandedText = $expandedText
    }
    $Label.Cursor = [Cursors]::Hand
    $Label.Text = $collapsedText
}

function Update-ChocolateySearchListItem {
    param(
        [System.Windows.Forms.ListBox]$ListBox,
        $Package
    )

    if ($null -eq $ListBox -or $ListBox.IsDisposed -or $null -eq $Package) {
        return
    }

    $targetIndex = -1
    for ($index = 0; $index -lt $ListBox.Items.Count; $index++) {
        if ($ListBox.Items[$index].Id -eq $Package.Id) {
            $targetIndex = $index
            break
        }
    }

    if ($targetIndex -lt 0) {
        return
    }

    if (-not ($ListBox.Tag -is [hashtable])) {
        $ListBox.Tag = @{}
    }

    $ListBox.Tag.SuppressSelectionChanged = $true

    try {
        $selectedIds = @($ListBox.SelectedItems | ForEach-Object { $_.Id })
        $topIndex = if ($ListBox.Items.Count -gt 0) { $ListBox.TopIndex } else { 0 }

        $updatedItem = [PSCustomObject]@{
            Id           = $Package.Id
            Name         = if ([string]::IsNullOrWhiteSpace($Package.Name)) { $Package.Id } else { $Package.Name }
            Version      = $Package.Version
            Title        = $Package.Title
            Published    = $Package.Published
            Authors      = $Package.Authors
            Tags         = $Package.Tags
            Summary      = $Package.Summary
            Description  = $Package.Description
            SoftwareSite = $Package.SoftwareSite
            DisplayName  = $Package.DisplayName
            Raw          = $Package.Raw
        }

        $ListBox.Items.RemoveAt($targetIndex)
        [void]$ListBox.Items.Insert($targetIndex, $updatedItem)
        $ListBox.DisplayMember = "DisplayName"

        if ($ListBox.Items.Count -gt 0) {
            $ListBox.TopIndex = [Math]::Min($topIndex, $ListBox.Items.Count - 1)
        }

        for ($index = 0; $index -lt $ListBox.Items.Count; $index++) {
            if ($selectedIds -contains $ListBox.Items[$index].Id -and -not $ListBox.GetSelected($index)) {
                $ListBox.SetSelected($index, $true)
            }
        }
    } finally {
        if ($ListBox.Tag -is [hashtable]) {
            $ListBox.Tag.SuppressSelectionChanged = $false
        }
    }
}

function Start-ChocolateySearchTitleEnrichment {
    param(
        [System.Windows.Forms.TextBox]$SearchBox,
        [System.Windows.Forms.ListBox]$ListBox,
        [object[]]$Results,
        [string]$Token,
        [int]$SearchDurationMs = 4000
    )

    if ($null -eq $SearchBox -or $SearchBox.IsDisposed -or $null -eq $ListBox -or $ListBox.IsDisposed) {
        return
    }

    if (-not ($SearchBox.Tag -is [hashtable])) {
        $SearchBox.Tag = @{}
    }

    Stop-ChocolateySearchTitleEnrichment -SearchBox $SearchBox

    $queue = [System.Collections.Queue]::new()
    foreach ($result in $Results) {
        $queue.Enqueue($result)
    }

    $timer = [System.Windows.Forms.Timer]::new()
    $timer.Interval = 150
    $timer.Tag = @{
        SearchBox = $SearchBox
        ListBox = $ListBox
        Queue = $queue
        Token = $Token
        SearchDurationMs = $SearchDurationMs
    }

    $timer.Add_Tick({
        $state = $this.Tag
        if ($null -eq $state -or $state.SearchBox.IsDisposed -or $state.ListBox.IsDisposed) {
            $this.Stop()
            $this.Dispose()
            return
        }

        if ($state.Token -ne $script:ChocolateySearchToken -or [string]::IsNullOrWhiteSpace($state.SearchBox.Text)) {
            Stop-ChocolateySearchTitleEnrichment -SearchBox $state.SearchBox
            return
        }

        $activeLookup = $state.SearchBox.Tag.TitleLookup
        if ($activeLookup) {
            $elapsedMs = [int]([System.DateTime]::UtcNow - $activeLookup.StartedAt).TotalMilliseconds
            if ($elapsedMs -ge $state.SearchDurationMs) {
                try {
                    if (-not $activeLookup.Process.HasExited) {
                        $activeLookup.Process.Kill()
                        [void]$activeLookup.Process.WaitForExit(500)
                    }
                } catch {
                } finally {
                    $activeLookup.Process.Dispose()
                    $state.SearchBox.Tag.TitleLookup = $null
                }
                return
            }

            if (-not $activeLookup.Process.HasExited) {
                return
            }

            try {
                [void]$activeLookup.Process.WaitForExit()
                $stdout = $activeLookup.StdOutTask.GetAwaiter().GetResult()
                $details = ConvertFrom-ChocolateyInfoText -Text $stdout -Name $activeLookup.Package.Id -FallbackVersion $activeLookup.Package.Version
                if ($details) {
                    [void](Set-CachedApplicationDetails -Name $details.Id -Manager "Chocolatey" -Details $details)
                    Update-ChocolateySearchListItem -ListBox $state.ListBox -Package $details
                }
            } catch {
            } finally {
                $activeLookup.Process.Dispose()
                $state.SearchBox.Tag.TitleLookup = $null
            }
            return
        }

        if ($state.Queue.Count -eq 0) {
            $this.Stop()
            $this.Dispose()
            $state.SearchBox.Tag.TitleEnrichmentTimer = $null
            return
        }

        $package = $state.Queue.Dequeue()
        $cachedDetails = Get-ApplicationDetailsFromCache -Name $package.Id -Manager "Chocolatey"
        if ($cachedDetails) {
            Update-ChocolateySearchListItem -ListBox $state.ListBox -Package $cachedDetails
            return
        }

        try {
            $psi = [System.Diagnostics.ProcessStartInfo]::new()
            $psi.FileName = (Get-Command choco -ErrorAction Stop).Source
            $psi.Arguments = "info `"$($package.Id)`""
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true

            $process = [System.Diagnostics.Process]::new()
            $process.StartInfo = $psi
            [void]$process.Start()

            $state.SearchBox.Tag.TitleLookup = @{
                Package = $package
                Process = $process
                StdOutTask = $process.StandardOutput.ReadToEndAsync()
                StartedAt = [System.DateTime]::UtcNow
            }
        } catch {
            $state.SearchBox.Tag.TitleLookup = $null
        }
    })

    $SearchBox.Tag.TitleEnrichmentTimer = $timer
    $timer.Start()
}



