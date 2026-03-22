<#
# Written by bibicadotnet – https://github.com/bibicadotnet/microsoft-edge-debloater
#>
param( [ScriptBlock]$ShowText )
if (-not $ShowText) { $ShowText = { param($msg) Write-Host $msg } }

# Prüfe, ob System.Windows.Forms bereits geladen ist, andernfalls lade es
if (-not ([AppDomain]::CurrentDomain.GetAssemblies().GetName().Name -contains "System.Windows.Forms")) {
    Add-Type -AssemblyName System.Windows.Forms
}

function Show-DialogBox {
    param (
        [string]$Message,
        [string]$Title,
        [string]$Buttons,
        [string]$Icon
    )
    # Konvertiere die Button-Parameter in die entsprechenden Enums
    switch ($Buttons) {
        "OK"    { $Buttons = [System.Windows.Forms.MessageBoxButtons]::OK }
        "YesNo" { $Buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo }
        default { $Buttons = [System.Windows.Forms.MessageBoxButtons]::OK }
    }
    # Konvertiere die Icon-Parameter in die entsprechenden Enums
    switch ($Icon) {
        "None"          { $Icon = [System.Windows.Forms.MessageBoxIcon]::None }
        "Information"   { $Icon = [System.Windows.Forms.MessageBoxIcon]::Information }
        "Warning"       { $Icon = [System.Windows.Forms.MessageBoxIcon]::Warning }
        "Error"         { $Icon = [System.Windows.Forms.MessageBoxIcon]::Error }
        default         { $Icon = [System.Windows.Forms.MessageBoxIcon]::None }
    }

    return [System.Windows.Forms.MessageBox]::Show($Message, $Title, $Buttons, $Icon)
}

# Bestätigungsdialog anzeigen
$confirm = Show-DialogBox -Message "Möchten Sie Microsoft Edge wirklich entfernen?" -Title "Bestätigung" -Buttons "YesNo" -Icon "Warning"
if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }

# Initial message
& $ShowText "Entferne Microsoft Edge..."

# Beende laufende Prozesse
& $ShowText "Beende Edge-Prozesse..."
$edgeProcesses = @("msedge", "MicrosoftEdgeUpdate", "edgeupdate", "edgeupdatem", "MicrosoftEdgeSetup")
foreach ($process in $edgeProcesses) {
    $currentProcesses = Get-Process -Name $process -ErrorAction SilentlyContinue
    if ($currentProcesses) { Stop-Process -Name $process -Force -ErrorAction SilentlyContinue }
}

# Entferne Dateien und Ordner
& $ShowText "Entferne Dateien und Ordner..."
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
foreach ($folder in $edgeFolders) { if (Test-Path $folder) { Remove-Item $folder -Recurse -Force -ErrorAction SilentlyContinue } }

# Entferne Verknüpfungen
& $ShowText "Entferne Verknüpfungen..."
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
            if (Test-Path $path) { Remove-Item $path -Force -ErrorAction SilentlyContinue }
        }
    } 
}

# Entferne Registrierungseinträge
& $ShowText "Entferne Registrierungseinträge..."
$edgeRegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge",
    "HKCU:\Software\Microsoft\Edge",
    "HKLM:\Software\Policies\Microsoft\Edge"
) 
foreach ($regPath in $edgeRegistryPaths) { if (Test-Path $regPath) { Remove-Item $regPath -Recurse -Force -ErrorAction SilentlyContinue } }

# Entferne StartMenuInternet-Einträge
& $ShowText "Entferne StartMenuInternet-Einträge..."
$startMenuInternetPaths = @(
    "HKLM:\SOFTWARE\Clients\StartMenuInternet",
    "HKLM:\SOFTWARE\WOW6432Node\Clients\StartMenuInternet", 
    "HKCU:\SOFTWARE\Clients\StartMenuInternet"
) 
foreach ($regPath in $startMenuInternetPaths) {
    if (Test-Path $regPath) {
        $regEdgePath = Get-ChildItem $regPath | Where-Object { $_.Name -like "*Microsoft Edge*" } 
        foreach ($edgeEntry in $regEdgePath) { Remove-Item $edgeEntry.PsPath -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# Entferne Deinstallations-Einträge
& $ShowText "Entferne Deinstallations-Einträge..."
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall", 
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
)
foreach ($regPath in $uninstallPaths) {
    if (Test-Path $regPath) {
        $regEdgePath = Get-ChildItem $regPath -ErrorAction SilentlyContinue | Where-Object {
            $displayName = (Get-ItemProperty $_.PsPath -Name DisplayName -ErrorAction SilentlyContinue).DisplayName
            $displayName -and $displayName -like "*Microsoft Edge*"
        }
        foreach ($edgeEntry in $regEdgePath) { Remove-Item $edgeEntry.PsPath -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# Entferne Windows Installer-Einträge
& $ShowText "Entferne Windows Installer-Einträge..."
$installerPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData",
    "HKLM:\SOFTWARE\Classes\Installer\Products",
    "HKLM:\SOFTWARE\Classes\Installer\Features", 
    "HKLM:\SOFTWARE\Classes\Installer\UpgradeCodes"
)
foreach ($regPath in $installerPaths) {
    if (Test-Path $regPath) {
        $regEdgePath = Get-ChildItem $regPath -Recurse -ErrorAction SilentlyContinue | Where-Object {
            $props = Get-ItemProperty $_.PsPath -ErrorAction SilentlyContinue
            ($props.ProductName -like "*Microsoft Edge*") -or ($props.DisplayName -like "*Microsoft Edge*")
        }
        foreach ($edgeEntry in $regEdgePath) { Remove-Item $edgeEntry.PsPath -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# Entferne Einträge aus registrierten Apps
& $ShowText "Entferne Einträge aus registrierten Apps..."
$regApps = "HKLM:\SOFTWARE\RegisteredApplications"
if (Test-Path $regApps) {
    $regEdgeApps = Get-ItemProperty $regApps -ErrorAction SilentlyContinue | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -like "*Microsoft Edge*" }
    foreach ($edgeApp in $regEdgeApps) { Remove-ItemProperty -Path $regApps -Name $edgeApp.Name -ErrorAction SilentlyContinue }
}

# Entferne geplante Aufgaben
& $ShowText "Entferne geplante Aufgaben..."
Get-ScheduledTask -TaskName "MicrosoftEdgeUpdate*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false

# Finish message
& $ShowText "Microsoft Edge wurde erfolgreich deinstalliert!" -Final
