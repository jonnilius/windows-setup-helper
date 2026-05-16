using namespace System.Windows.Forms
using namespace System.Security.Principal

param ( [switch]$Silent, [switch]$Force, [string]$ExpectedSha256 = "276A8250EC0996255EA15D4278BDCF9D6052792D1B33CCA16421AB5BEBADF03F" )
$ErrorActionPreference = "SilentlyContinue"

Add-Type -AssemblyName System.Windows.Forms

# Administratorrechte überprüfen
if (-not ([WindowsPrincipal] [WindowsIdentity]::GetCurrent()).IsInRole([WindowsBuiltInRole]::Administrator)) {
    if ($Force) { 
        $params = "-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath
        if ($Silent) { $params += " -Silent" } elseif ($Force) { $params += " -Force" }
        Start-Process powershell.exe -ArgumentList $params -Verb RunAs; return 
        [System.Environment]::Exit(0)
    }
    [MessageBox]::Show("Dieses Skript muss mit Administratorrechten ausgeführt werden. Bitte starte die PowerShell als Administrator und versuche es erneut.", "Administratorrechte erforderlich", [MessageBoxButtons]::OK, [MessageBoxIcon]::Warning)
    return
}

# ProgressDialog Funktionen definieren (Platzhalter, wenn nicht bereits definiert)
if ($Silent) { 
    function Show-ProgressDialog {}
    function Update-ProgressDialog {}
    function Close-ProgressDialog {} 
} else {
    if (-not (Get-Command Show-ProgressDialog))     { function Show-ProgressDialog      { param ( $Title, $Status ) Write-Host "`n -- $Title -- " -ForegroundColor Cyan; Write-Host "$Status" } }
    if (-not (Get-Command Update-ProgressDialog))   { function Update-ProgressDialog    { param ( $Title, $Status ) if ($Status) { Write-Host "$Title - $Status" } else { Write-Host $Title } } }
    if (-not (Get-Command Close-ProgressDialog))    { function Close-ProgressDialog     { param ( $Title, $Status ) if ($Status) { Write-Host "$Title - $Status" } else { Write-Host $Title }; Write-Host " -- Manuel Hoefs --`n" -ForegroundColor Cyan } }
}

function Invoke-DownloadUltraUXThemePatcher {
    param( [string]$OutFile = (Join-Path ([IO.Path]::GetTempPath()) "WindowsSetupHelper\UltraUXThemePatcher-$([guid]::NewGuid().Guid)\UltraUXThemePatcher.exe") )

    try {
        Show-ProgressDialog "UltraUXThemePatcher" "Lade UltraUXThemePatcher herunter..."
        Stop-UltraUXThemePatcherProcess

        $targetDirectory = Split-Path -Path $OutFile -Parent
        if (-not (Test-Path $targetDirectory)) {
            New-Item -Path $targetDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        Invoke-WebRequest -Uri "https://mhoefs.eu/software_count.php" -Method POST `
            -Body @{
                Uxtheme = "UltraUXThemePatcher"
                id      = "Uxtheme"
            } -OutFile $OutFile -ErrorAction Stop

        if (-not (Test-Path $OutFile)) { throw "Download fehlgeschlagen: Datei wurde nicht erstellt." }

        $file = Get-Item $OutFile -ErrorAction Stop
        if ($file.Length -le 0) { throw "Download fehlgeschlagen: Datei ist leer." }

        Update-ProgressDialog "Download abgeschlossen"
        return $file.FullName
    }
    catch {
        Close-ProgressDialog "Fehler beim Download: $($_.Exception.Message)"
        throw
    }
}

function Stop-UltraUXThemePatcherProcess {
    $processes = Get-CimInstance Win32_Process -Filter "Name = 'UltraUXThemePatcher.exe'" -ErrorAction SilentlyContinue
    if (-not $processes) { return }

    foreach ($process in $processes) {
        Update-ProgressDialog "UltraUXThemePatcher" "Beende blockierenden Prozess: PID $($process.ProcessId)"
        Stop-Process -Id $process.ProcessId -Force -ErrorAction Stop
        Start-Sleep -Milliseconds 500
    }
}

function Test-InstallerTrust {
    param( [Parameter(Mandatory = $true)][string]$Path, [string]$ExpectedSha256 )

    if (-not (Test-Path $Path)) { throw "Validierung fehlgeschlagen: Installer wurde nicht gefunden." }

    Update-ProgressDialog "Prüfe SHA256-Hash..."
    $hash = (Get-FileHash -Path $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()

    if ($ExpectedSha256) {
        $expected = $ExpectedSha256.Trim().ToUpperInvariant()
        if ($hash -ne $expected) { throw "Hash-Prüfung fehlgeschlagen. Erwartet: $expected, erhalten: $hash" }

        Update-ProgressDialog "Hash-Prüfung erfolgreich."
        return [pscustomobject]@{
            Path       = $Path
            Sha256     = $hash
            Signature  = $null
            Validation = "Hash"
        }
    }

    Update-ProgressDialog "Prüfe digitale Signatur..."
    $signature = Get-AuthenticodeSignature -FilePath $Path -ErrorAction Stop
    if ($signature.Status -ne "Valid") {
        throw "Signatur-Prüfung fehlgeschlagen: $($signature.Status). Erwarteten SHA256-Hash per -ExpectedSha256 übergeben. Aktueller SHA256: $hash"
    }

    Update-ProgressDialog "Signatur gültig: $($signature.SignerCertificate.Subject)"
    return [pscustomobject]@{
        Path       = $Path
        Sha256     = $hash
        Signature  = $signature
        Validation = "Signature"
    }
}

function Start-UltraUXThemePatcherInstaller {
    param( [Parameter(Mandatory = $true)][string]$Path )

    Update-ProgressDialog "UltraUXThemePatcher" "Starte Installer..."
    $process = Start-Process -FilePath $Path -Wait -PassThru -ErrorAction Stop

    return $process.ExitCode
}

function Resolve-InstallerExitCode {
    param( [int]$ExitCode )

    switch ($ExitCode) {
        0       { return @{ Success = $true;  RebootRequired = $false; Message = "Installation erfolgreich abgeschlossen." } }
        3010    { return @{ Success = $true;  RebootRequired = $true;  Message = "Installation erfolgreich abgeschlossen. Neustart erforderlich." } }
        1641    { return @{ Success = $true;  RebootRequired = $true;  Message = "Installation erfolgreich abgeschlossen. Neustart wurde angefordert." } }
        1       { return @{ Success = $false; RebootRequired = $false; Message = "Installer wurde abgebrochen oder konnte nicht initialisiert werden." } }
        default { return @{ Success = $false; RebootRequired = $false; Message = "Installer wurde mit ExitCode $ExitCode beendet." } }
    }
}

try {
    $installerPath = Invoke-DownloadUltraUXThemePatcher

    $trust = Test-InstallerTrust -Path $installerPath -ExpectedSha256 $ExpectedSha256
    Update-ProgressDialog "Validierung erfolgreich ($($trust.Validation), SHA256: $($trust.Sha256.Substring(0, 12))...)."

    $exitCode = Start-UltraUXThemePatcherInstaller -Path $installerPath
    $result = Resolve-InstallerExitCode -ExitCode $exitCode

    if ($result.Success) {
        Close-ProgressDialog "UltraUXThemePatcher" "$($result.Message) ExitCode: $exitCode"
        $script:UltraUXThemePatcherExitCode = 0
        return
    }

    Close-ProgressDialog "UltraUXThemePatcher fehlgeschlagen" "$($result.Message)"
    $script:UltraUXThemePatcherExitCode = $exitCode
    return
}
catch {
    Close-ProgressDialog "UltraUXThemePatcher fehlgeschlagen" $_.Exception.Message
    $script:UltraUXThemePatcherExitCode = 1
    return
}
