using namespace System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms

if (-not $script:ApplicationCache) { $script:ApplicationCache = @{} }
if (-not $script:ApplicationDetailsCache) { $script:ApplicationDetailsCache = @{} }

function Get-ApplicationDisplayName {
    param(
        [Parameter(Mandatory = $true)]
        $Package
    )

    if ($null -eq $Package) { return "" }

    $versionText = if (Test-Empty $Package.Version) { "" } else { " v$($Package.Version)" }
    $nameText = if (-not (Test-Empty $Package.Title)) { $Package.Title }
    elseif (-not (Test-Empty $Package.Name)) { $Package.Name }
    elseif (-not (Test-Empty $Package.Id)) { $Package.Id }
    else { "" }

    return "$nameText$versionText"
}



<# APPLICATION #>
function Get-Application {
    param( 
        [string]$Name, 
        [string]$Manager,

        [switch]$Cache,
        [switch]$DisplayName,
        $Package,
        [int]$Time = 8000 # Millisekunden, die maximal auf die Rückgabe von Anwendungsdetails gewartet wird
    )


    try {
        $process = Start-ShellProcess (Get-ChocolateySource) "info `"$Name`""

        $startedAt = [System.DateTime]::UtcNow
        while (-not $process.HasExited) {
            Start-Sleep -Milliseconds 60
            if ("System.Windows.Forms.Application" -as [type]) { [Application]::DoEvents() }

            $elapsedTime = [int]([System.DateTime]::UtcNow - $startedAt).TotalMilliseconds
            if ($elapsedTime -ge $Time) {
                Stop-ShellProcess -Process $process
                return $null
            }
        }

        $stdOut = $process.StandardOutput.ReadToEnd()
        $stdErr = $process.StandardError.ReadToEnd()
        if (-not (Test-Empty $stdErr)) { Write-Warning "Fehler beim Abrufen der Anwendungsdetails für '$Name': $stdErr" }

        $details = ConvertFrom-ChocolateyInfoText -Text $stdOut -Name $Name
        $script:ApplicationDetailsCache["$Manager::$Name"] = $details
        return $details
    } catch {
        Write-Warning "Fehler beim Abrufen der Anwendungsdetails für '$Name': $_"
        return $null
    }
}
function Set-Application {
    param( [string]$Name, [string]$Manager, $Details )

    if ($null -eq $Details) { return }

    $cacheKey = "$Manager::$Name"
    $script:ApplicationCache[$cacheKey] = $Details
    return $Details
}
function Install-Application {
    param( [string]$Name, [string]$Manager )
    
    switch ($Manager) {
        "Choco"      { $Manager = "Chocolatey" }
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
    
    switch ($Manager) {
        "Choco"       { $Manager = "Chocolatey" }
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
        [string]$Query,         # Suchbegriff für die Paketsuche
        [string]$Manager,       # Paketmanager, z.B. "Chocolatey"
        [int]$Time = 12,        # Dauer der Suche in Sekunden
        [string]$SearchToken,   # Token zur Identifikation der aktuellen Suche (z.B. für Abbruchbedingungen)

        [System.Windows.Forms.TextBox]$SearchBox  # Optionales TextBox-Steuerelement für die Sucheingabe
    )

    # Zu Beginn die Dauer der Suche in Millisekunden umrechnen und den Startzeitpunkt erfassen
    $SearchDuration = $Time * 1000
    $startedAt      = [System.DateTime]::UtcNow
    
    switch ($Manager) {
        "Choco"         { $Manager = "Chocolatey" }
        "Chocolatey"    {
            Write-Information "Suche nach Chocolatey-Paketen mit Query: $Query"
            try {

                # Prozess für die Suche starten 
                $process = Start-ShellProcess (Get-ChocolateySource) "search `"$Query`" --limit-output"

                # Prozess überwachen und Ergebnisse sammeln, bis die Suche abgeschlossen ist oder die Zeit abgelaufen ist
                while (-not $process.HasExited) {
                    Start-Sleep -Milliseconds 60  # Kurze Pause, um CPU-Last zu reduzieren
                    if ("System.Windows.Forms.Application" -as [type]) { [Application]::DoEvents() } # UI-Thread responsive halten

                    # Überprüfe die Dauer der Suche
                    $elapsedTime = [int]([System.DateTime]::UtcNow - $startedAt).TotalMilliseconds
                    if ($elapsedTime -ge $SearchDuration) {
                        Stop-ShellProcess -Process $process
                        Write-Warning "Suche nach '$Query' wurde nach $Time Sekunden beendet (Timeout)."
                        return @()
                    }

                    # Suche abbrechen, wenn die Suchanfrage im Suchfeld geändert wurde
                    if ($SearchBox -and -not $SearchBox.IsDisposed -and $SearchBox.Text.Trim() -ne $Query) {
                        Stop-ShellProcess -Process $process; return @()
                    }
                    
                }
                
                # Fehlerausgabe protokollieren, falls vorhanden
                $stdErr = $process.StandardError.ReadToEnd()
                if (-not (Test-Empty $stdErr)) { Write-Warning "Chocolatey-Suche meldet Fehler: $stdErr" }

                # Standardausgabe und Fehlerausgabe des Prozesses lesen
                $stdOut     = $process.StandardOutput.ReadToEnd()
                $lines      = @($stdOut -split "`r?`n" | Where-Object { -not (Test-Empty $_) })
                $results    = foreach ($line in $lines) {
                    if ($line -match '^([^|]+)\|(.+)$') {
                        $id      = $matches[1].Trim()
                        $version = $matches[2].Trim()

                        # Erst schnelle Basisergebnisse liefern; Detailanreicherung passiert asynchron in Start-Search.
                        [PSCustomObject]@{
                            Id          = $id
                            Name        = $id
                            Version     = $version
                            Title       = ""
                            DisplayName = if (Test-Empty $version) { $id } else { "$id v$version" }
                            Raw         = $line
                        }
                    }
                }
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
                return @()
            }
        }
        
        default {
            Write-Information "Suche nach Paketen mit Query: $Query"
        }
    }
}
function Test-Application {
    param( [string]$Name, [string]$Manager )
    
    switch ($Manager) {
        "Choco"      { $Manager = "Chocolatey" }
        "Chocolatey" { 
            Write-Information "Teste, ob Chocolatey-Paket installiert ist: $Name"
            try {
                $result     = choco list --id-only --exact $Name --limit-output
                $notEmpty   = Test-Empty $result
                $listMatch  = $result -match "^$Name\|"
                return $notEmpty -and $listMatch
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
    
    switch ($Manager) {
        "Choco"      { $Manager = "Chocolatey" }
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

<# CACHE #>
function Get-Cache {
    param( 
        [string]$Name, 
        [ValidateSet("Chocolatey", "WinGet")][string]$Manager,
        [switch]$ApplicationDetails
    )
    # Cache-Schlüssel für die Anwendung generieren
    $cacheKey = "$Manager::$Name"

    # Cache überprüfen und zurückgeben, falls vorhanden
    if ($script:ApplicationDetailsCache.ContainsKey($cacheKey)) { return $script:ApplicationDetailsCache[$cacheKey] }

    # Anwendungsdetails abrufen, wenn der entsprechende Switch gesetzt ist
    $details = Get-Application -Name $Name -Manager $Manager 

    # Anwendungsdetails im Cache speichern, falls erfolgreich abgerufen
    if ($details) {
        $details.DisplayName = Get-ApplicationDisplayName -Package $details
        $script:ApplicationDetailsCache[$cacheKey] = $details
    }

    return $details
}



<# CHOCOLATEY #>
function Test-Chocolatey {
    Write-Information "Prüfe, ob Chocolatey installiert ist..."
    try {
        # Prüfen, ob der Befehl "choco" verfügbar ist, ohne eine Fehlermeldung auszugeben
        $CommandSource      = (Get-Command choco -ErrorAction SilentlyContinue).Source
        $NullOrWhitespace   = [string]::IsNullOrWhiteSpace($CommandSource)
        return -not $NullOrWhitespace
    } catch {
        # Wenn ein Fehler auftritt (z.B. Befehl nicht gefunden), wird false zurückgegeben
        Write-Warning "Fehler beim Testen von Chocolatey: $_"
        return $false
    }
}
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
    if (Test-Chocolatey) {
        Write-Information "Chocolatey wurde erfolgreich installiert."
        Show-MessageBox "InstallChocolateySuccess"
    } else {
        Write-Warning "Fehler: Chocolatey konnte nicht installiert werden."
        Show-MessageBox "InstallChocolateyFailed"
    }
}
function Uninstall-Chocolatey {
    # Bestätigung der Deinstallation einholen
    $confirm = Show-MessageBox "ConfirmUninstallChocolatey"
    if (-not $confirm) { Write-Information "Deinstallation von Chocolatey abgebrochen."; return }

    # Umgebungsvariable für Chocolatey-Installation überprüfen
    Write-Information "Überprüfe Chocolatey-Installation und PATH-Variablen..."
    if (-not $env:ChocolateyInstall) { 
        Write-Information "Chocolatey ist nicht installiert oder die Umgebungsvariable fehlt."
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
    if ($env:ChocolateyToolsLocation -and (Test-Path $env:ChocolateyToolsLocation)) { Remove-Item -Path $env:ChocolateyToolsLocation -Recurse -Force }

    foreach ($scope in 'User', 'Machine') { [Environment]::SetEnvironmentVariable('ChocolateyToolsLocation', [string]::Empty, $scope) }
    Write-Information "Deinstallation von Chocolatey abgeschlossen."

    # Mitteilung an den Benutzer abschließen
    Show-MessageBox "UninstallChocolateySuccess"
}
function Get-ChocolateySource {
    $command = Get-Command choco -ErrorAction Stop
    return $command.Source
}







<# SEARCH FUNCTIONS #>
function Start-Search {
    param(
        [System.Windows.Forms.TextBox]$SearchBox,
        [System.Windows.Forms.ListBox]$ListBox,

        [object[]]$Results,
        [string]$Token,
        [int]$SearchDuration = 12000
    )

    # Sicherstellen, dass die Steuerelemente gültig sind
    if ($null -eq $SearchBox -or $SearchBox.IsDisposed) { return }
    if ($null -eq $ListBox -or $ListBox.IsDisposed) { return }

    # Sicherstellen, dass das Suchfeld über die erwarteten Tag-Strukturen verfügt
    if (-not ($SearchBox.Tag -is [hashtable])) { $SearchBox.Tag = @{} }

    # Beenden laufender Suchvorgänge und Titelanreicherungen, um Konflikte zu vermeiden
    Stop-Search -SearchBox $SearchBox

    # Ergebnisse in die Warteschlange einfügen
    $queue = [System.Collections.Queue]::new()
    foreach ($result in $Results) { $queue.Enqueue($result) }

    # Timer für die schrittweise Anzeige von Suchergebnissen einrichten
    $timer = [Timer]::new()
    $timer.Interval = 150
    $timer.Tag = @{
        ListBox         = $ListBox
        SearchBox       = $SearchBox
        Queue           = $queue
        Token           = $Token
        SearchDuration  = $SearchDuration
    }
    $timer.Add_Tick({
        if ($null -eq $this.Tag) { $this.Stop(); $this.Dispose(); return }
        $state      = $this.Tag
        $searchBox  = $state.SearchBox
        $listBox    = $state.ListBox
        
        # Sicherstellen, dass die Steuerelemente noch gültig sind
        if ($searchBox.IsDisposed -or $listBox.IsDisposed) { $this.Stop(); $this.Dispose(); return }

        # Suche abbrechen, wenn das Token nicht mehr übereinstimmt oder die Suchanfrage geändert wurde
        if ($state.Token -ne $script:SearchToken -or (Test-Empty $searchBox.Text)) { Stop-Search -SearchBox $searchBox; return }

        
        $activeLookup = $searchBox.Tag.TitleLookup
        if ($activeLookup) {
            $elapsedMs = [int]([System.DateTime]::UtcNow - $activeLookup.StartedAt).TotalMilliseconds
            if ($elapsedMs -ge $state.SearchDuration) {
                try {
                    if (-not $activeLookup.Process.HasExited) {
                        $activeLookup.Process.Kill()
                        [void]$activeLookup.Process.WaitForExit(500)
                    }
                } catch {  
                } finally {
                    $activeLookup.Process.Dispose()
                    $searchBox.Tag.TitleLookup = $null
                }
                return
            }

            # Schutz gegen unbeabsichtigte Auslösung während der Aktualisierung der Liste
            if ( -not $activeLookup.Process.HasExited ) { return }

            try {
                [void]$activeLookup.Process.WaitForExit()
                $stdout = $activeLookup.StdOutTask.GetAwaiter().GetResult()
                $details = ConvertFrom-ChocolateyInfoText -Text $stdout -Name $activeLookup.PackageId
                if ($details) {
                    [void](Set-Application -Name $details.Id -Manager "Chocolatey" -Details $details)
                    Update-Search -ListBox $listBox -Package $details
                } 
            } catch {
            } finally {
                $activeLookup.Process.Dispose()
                $searchBox.Tag.TitleLookup = $null
            }
            return
        }

        if ($state.Queue.Count -eq 0) {
            $this.Stop()
            $this.Dispose()
            $searchBox.Tag.TitleEnrichmentTimer = $null
            return
        }

        $package = $state.Queue.Dequeue()
        $cachedDetails = Get-Cache -Name $package.Id -Manager "Chocolatey" -ApplicationDetails
        if ($cachedDetails) {
            Update-Search -ListBox $listBox -Package $cachedDetails
            return
        }

        try {
            $psi = [System.Diagnostics.ProcessStartInfo]::new()
            $psi.FileName = (Get-Command choco -ErrorAction Stop).Source
            $psi.Arguments = "info `"$package.Id`""
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true

            $process = [System.Diagnostics.Process]::new()
            $process.StartInfo = $psi
            [void]$process.Start()

            $searchBox.Tag.TitleLookup = @{
                Process     = $process
                StdOutTask  = $process.StandardOutput.ReadToEndAsync()
                PackageId   = $package.Id
                StartedAt   = [System.DateTime]::UtcNow
            }
        } catch {
            $searchBox.Tag.TitleLookup = $null
        }
    })

    $SearchBox.Tag.TitleEnrichmentTimer = $timer
    $timer.Start()
}
function Stop-Search {
    param( [System.Windows.Forms.TextBox]$SearchBox )

    # Sicherstellen, dass das Suchfeld gültig ist und über die erwarteten Tag-Strukturen verfügt
    if ($null -eq $SearchBox -or $SearchBox.IsDisposed) { return }
    if (-not ($SearchBox.Tag -is [hashtable])) { return }

    # Timer für die schrittweise Anzeige von Suchergebnissen stoppen und bereinigen
    if ($SearchBox.Tag.ContainsKey("TitleEnrichmentTimer") -and $SearchBox.Tag.TitleEnrichmentTimer) {
        $SearchBox.Tag.TitleEnrichmentTimer.Stop()
        $SearchBox.Tag.TitleEnrichmentTimer.Dispose()
        $SearchBox.Tag.TitleEnrichmentTimer = $null
    }

    # Laufenden Prozess für die Titelanreicherung beenden, falls vorhanden
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
function Update-Search {
    param ( [System.Windows.Forms.ListBox]$ListBox, $Package )
    if ($null -eq $ListBox -or $ListBox.IsDisposed -or $null -eq $Package) { return }

    $targetIndex = -1
    for ($index = 0; $index -lt $ListBox.Items.Count; $index++) {
        if ($ListBox.Items[$index].Id -eq $Package.Id) { $targetIndex = $index; break }
    }

    if ($targetIndex -lt 0) { return }
    if (-not ($ListBox.Tag -is [hashtable])) { $ListBox.Tag = @{} }

    $ListBox.Tag.SuppressSelectionChanged = $true
    try {
        $selectedIds = @($ListBox.SelectedItems | ForEach-Object { $_.Id })
        $topIndex = if ($ListBox.Items.Count -gt 0) { $ListBox.TopIndex } else { 0 }

        $updatedItem = [PSCustomObject]@{
            Id          = $Package.Id
            Name        = if (Test-Empty $Package.Name) { $Package.Id } else { $Package.Name }
            Version     = $Package.Version
            Title       = $Package.Title
            Published    = $Package.Published
            Authors      = $Package.Authors
            Tags         = $Package.Tags
            Summary      = $Package.Summary
            Description  = $Package.Description
            SoftwareSite = $Package.SoftwareSite
            DisplayName = Get-ApplicationDisplayName -Package $Package
            Raw         = $ListBox.Items[$targetIndex].Raw
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
        if ($ListBox.Tag -is [hashtable]){ $ListBox.Tag.SuppressSelectionChanged = $false }
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
