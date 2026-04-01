<# INSTALL #>
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


<# SEARCH #>
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
                        [PSCustomObject]@{
                            Id          = $id
                            Name        = $id
                            Version     = $version
                            DisplayName = "$id v$version"
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

                $details = [ordered]@{
                    Id           = $Name
                    Version      = ""
                    Title        = ""
                    Authors      = ""
                    Tags         = ""
                    Summary      = ""
                    SoftwareSite = ""
                }

                foreach ($line in ($stdOut -split "`r?`n")) {
                    $trimmed = $line.Trim()
                    if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }

                    # Example first package line: "7zip 26.0.0 [Approved]"
                    if ($trimmed -match '^([^\s]+)\s+([^\s]+)\s+\[.*\]$' -and [string]::IsNullOrWhiteSpace($details.Version)) {
                        $details.Id = $matches[1].Trim()
                        $details.Version = $matches[2].Trim()
                        continue
                    }
                    if ($trimmed -match '^Title:\s*([^|]+)') { $details.Title = $matches[1].Trim(); continue }
                    if ($trimmed -match '^Authors:\s*(.+)$') { $details.Authors = $matches[1].Trim(); continue }
                    if ($trimmed -match '^Tags:\s*(.+)$') { $details.Tags = $matches[1].Trim(); continue }
                    if ($trimmed -match '^Summary:\s*(.+)$') { $details.Summary = $matches[1].Trim(); continue }
                    if ($trimmed -match '^Software Site:\s*(.+)$') { $details.SoftwareSite = $matches[1].Trim(); continue }
                }

                return [PSCustomObject]$details
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

<# UPDATE #>
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


<# UNINSTALL #>
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