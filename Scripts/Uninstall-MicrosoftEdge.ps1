<# Written by bibicadotnet – https://github.com/bibicadotnet/microsoft-edge-debloater #>
param( [switch]$Silent, [switch]$Force )
$ErrorActionPreference = "SilentlyContinue"
Add-Type -AssemblyName System.Windows.Forms


# Administratorrechte überprüfen
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($Force) { 
        $params = "-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath
        if ($Silent) { $params += " -Silent" } elseif ($Force) { $params += " -Force" }
        Start-Process powershell.exe -ArgumentList $params -Verb RunAs; return 
        [System.Environment]::Exit(0)
    }
    [System.Windows.Forms.MessageBox]::Show("Dieses Skript muss mit Administratorrechten ausgeführt werden. Bitte starte die PowerShell als Administrator und versuche es erneut.", "Administratorrechte erforderlich", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    return
}

if ($Silent) {
    function Show-ProgressDialog    { }
    function Update-ProgressDialog  { }
    function Close-ProgressDialog   { }
} else {
    if (-not (Get-Command Show-ProgressDialog)) { function Show-ProgressDialog { param ( $Title, $Message ) Write-Host "`n -- $Title -- " -ForegroundColor Cyan; Write-Host "$Message" } }
    if (-not (Get-Command Update-ProgressDialog)) { function Update-ProgressDialog { param ( $Message ) Write-Host $Message } }
    if (-not (Get-Command Close-ProgressDialog)) { function Close-ProgressDialog { param ( $Message ) Write-Host $Message; Write-Host " -- by bibicadotnet --`n" -ForegroundColor Cyan } }
}

# Prüfe, ob System.Windows.Forms bereits geladen ist, andernfalls lade es
if (-not $Silent -and -not $Force) { 
    # Bestätigungsdialog anzeigen
    $confirm = [System.Windows.Forms.MessageBox]::Show("Möchten Sie Microsoft Edge wirklich entfernen?", "Bestätigung", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }
}

# Initial message
Show-ProgressDialog "Microsoft Edge Entfernen" "Entferne Microsoft Edge..."

# Beende laufende Prozesse
Update-ProgressDialog "Beende Edge-Prozesse..."
$edgeProcesses = @("msedge", "MicrosoftEdgeUpdate", "edgeupdate", "edgeupdatem", "MicrosoftEdgeSetup")
foreach ($process in $edgeProcesses) {
    $currentProcesses = Get-Process -Name $process
    if ($currentProcesses) { Stop-Process -Name $process -Force }
}

# Entferne Dateien und Ordner
Update-ProgressDialog "Entferne Dateien und Ordner..."
$edgeFolders = @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge",
    "${env:ProgramFiles(x86)}\Microsoft\Edge Beta", 
    "${env:ProgramFiles(x86)}\Microsoft\Edge Dev",
    "${env:ProgramFiles(x86)}\Microsoft\Edge Canary",
    "${env:ProgramFiles(x86)}\Microsoft\EdgeCore",
    "${env:ProgramFiles(x86)}\Microsoft\EdgeUpdate",
    "${env:LOCALAPPDATA}\Microsoft\EdgeUpdate",
    "${env:LOCALAPPDATA}\Microsoft\EdgeCore", 
    "${env:LOCALAPPDATA}\Microsoft\Edge SxS\Application"
) 
foreach ($folder in $edgeFolders) { if (Test-Path $folder) { Remove-Item $folder -Recurse -Force } }

# Entferne Verknüpfungen
Update-ProgressDialog "Entferne Verknüpfungen..."
$edgeVariants = "Microsoft Edge", "Microsoft Edge Beta", "Microsoft Edge Dev", "Microsoft Edge Canary"
$locations    = @(
    [Environment]::GetFolderPath("Desktop"),
    [Environment]::GetFolderPath("CommonDesktopDirectory"), 
    [Environment]::GetFolderPath("Programs"),
    [Environment]::GetFolderPath("CommonPrograms"),
    (Join-Path ([Environment]::GetFolderPath("CommonPrograms")) "Microsoft")
)
foreach ($location in $locations) { 
    if (Test-Path $location) { 
        foreach ($name in $edgeVariants) {
            $path = Join-Path $location "$name.lnk"
            if (Test-Path $path) { Remove-Item $path -Force }
        }
    } 
}

# Entferne Registrierungseinträge
Update-ProgressDialog "Entferne Registrierungseinträge..."
$edgeRegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge",
    "HKCU:\Software\Microsoft\Edge",
    "HKLM:\Software\Policies\Microsoft\Edge"
) 
foreach ($regPath in $edgeRegistryPaths) { if (Test-Path $regPath) { Remove-Item $regPath -Recurse -Force } }

# Entferne StartMenuInternet-Einträge
Update-ProgressDialog "Entferne StartMenuInternet-Einträge..."
$startMenuInternetPaths = @(
    "HKLM:\SOFTWARE\Clients\StartMenuInternet",
    "HKLM:\SOFTWARE\WOW6432Node\Clients\StartMenuInternet", 
    "HKCU:\SOFTWARE\Clients\StartMenuInternet"
) 
foreach ($regPath in $startMenuInternetPaths) {
    if (Test-Path $regPath) {
        $regEdgePath = Get-ChildItem $regPath | Where-Object { $_.Name -like "*Microsoft Edge*" } 
        foreach ($edgeEntry in $regEdgePath) { Remove-Item $edgeEntry.PsPath -Recurse -Force }
    }
}

# Entferne Deinstallations-Einträge
Update-ProgressDialog "Entferne Deinstallations-Einträge..."
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall", 
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
)
foreach ($regPath in $uninstallPaths) {
    if (Test-Path $regPath) {
        $regEdgePath = Get-ChildItem $regPath | Where-Object {
            $displayName = (Get-ItemProperty $_.PsPath -Name DisplayName).DisplayName
            $displayName -and $displayName -like "*Microsoft Edge*"
        }
        foreach ($edgeEntry in $regEdgePath) { Remove-Item $edgeEntry.PsPath -Recurse -Force }
    }
}

# Entferne Windows Installer-Einträge
Update-ProgressDialog "Entferne Windows Installer-Einträge..."
$installerPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData",
    "HKLM:\SOFTWARE\Classes\Installer\Products",
    "HKLM:\SOFTWARE\Classes\Installer\Features", 
    "HKLM:\SOFTWARE\Classes\Installer\UpgradeCodes"
)
foreach ($regPath in $installerPaths) {
    if (Test-Path $regPath) {
        $regEdgePath = Get-ChildItem $regPath -Recurse | Where-Object {
            $props = Get-ItemProperty $_.PsPath
            ($props.ProductName -like "*Microsoft Edge*") -or ($props.DisplayName -like "*Microsoft Edge*")
        }
        foreach ($edgeEntry in $regEdgePath) { Remove-Item $edgeEntry.PsPath -Recurse -Force }
    }
}

# Entferne Einträge aus registrierten Apps
Update-ProgressDialog "Entferne Einträge aus registrierten Apps..."
$regApps = "HKLM:\SOFTWARE\RegisteredApplications"
if (Test-Path $regApps) {
    $regEdgeApps = Get-ItemProperty $regApps | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -like "*Microsoft Edge*" }
    foreach ($edgeApp in $regEdgeApps) { Remove-ItemProperty -Path $regApps -Name $edgeApp.Name }
}

# Entferne geplante Aufgaben
Update-ProgressDialog "Entferne geplante Aufgaben..."
Get-ScheduledTask -TaskName "MicrosoftEdgeUpdate*" | Unregister-ScheduledTask -Confirm:$false

# Finish message
Close-ProgressDialog "Microsoft Edge wurde erfolgreich deinstalliert!"

