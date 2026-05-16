using namespace System.Windows.Forms

param ( [switch]$Silent, [switch]$Force )
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

if ($Silent) { function Show-ProgressDialog { }; function Update-ProgressDialog { }; function Close-ProgressDialog { } }
else {
    if (-not (Get-Command Show-ProgressDialog))     { function Show-ProgressDialog      { param ( $Title, $Message ) Write-Host "`n -- $Title -- " -ForegroundColor Cyan; Write-Host "$Message" } }
    if (-not (Get-Command Update-ProgressDialog))   { function Update-ProgressDialog    { param ( $Message ) Write-Host $Message } }
    if (-not (Get-Command Close-ProgressDialog))    { function Close-ProgressDialog     { param ( $Message ) Write-Host $Message; Write-Host " --  --`n" -ForegroundColor Cyan } }
}

# Bestätigungsdialog anzeigen, wenn nicht im Silent- oder Force-Modus
if (-not $Silent -and -not $Force) { 
    # Bestätigungsdialog anzeigen
    $confirm = [System.Windows.Forms.MessageBox]::Show("Möchtest du wirklich alle Startmenü-Icons entfernen?", "Bestätigung", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }
}


# Statusmeldung anzeigen
Show-ProgressDialog "Startmenü-Icons entfernen" "Entferne Startmenü-Icons..."

# Definiere Startmenü-Layout als XML-String
Update-ProgressDialog "Definiere ein Startmenü-Layout..."
$layoutFile = "C:\Windows\StartMenuLayout.xml"
If ( Test-Path $layoutFile ) { Remove-Item $layoutFile }
$START_MENU_LAYOUT = @"
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
<LayoutOptions StartTileGroupCellWidth="6" />
<DefaultLayoutOverride>
<StartLayoutCollection>
    <defaultlayout:StartLayout GroupCellWidth="6" />
</StartLayoutCollection>
</DefaultLayoutOverride>
</LayoutModificationTemplate>
"@
$START_MENU_LAYOUT | Out-File $layoutFile -Encoding ASCII

# Weise das Startlayout zu und erzwinge die Anwendung mit "LockedStartLayout" sowohl auf Maschinen- als auch auf Benutzerebene
Update-ProgressDialog "Startmenü-Layout zuweisen und Anwendung erzwingen..."
$regAliases = @("HKLM", "HKCU")
foreach ($regAlias in $regAliases){
    $basePath   = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
    $keyPath    = $basePath + "\Explorer" 

    if(!(Test-Path -Path $keyPath)) { New-Item -Path $basePath -Name "Explorer" }

    Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 1
    Set-ItemProperty -Path $keyPath -Name "StartLayoutFile" -Value $layoutFile
}

# Explorer neu starten, damit die Änderungen wirksam werden
Update-ProgressDialog "Starte den Explorer neu..."
Stop-Process -name explorer -Force
Start-Sleep -Seconds 3

# Öffne das Startmenü, damit die Layout-Änderungen angewendet werden, und warte kurz, um sicherzustellen, dass alles aktualisiert ist.
Update-ProgressDialog "Öffne das Startmenü, damit die Layout-Änderungen angewendet werden..."
$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^{ESCAPE}')
Start-Sleep -Seconds 3

# Entfernen der Sperre, damit Benutzer das Startmenü-Layout wieder anpassen können, falls gewünscht.
Update-ProgressDialog "Entferne die Sperre, damit Benutzer das Startmenü-Layout wieder anpassen können..."
foreach ($regAlias in $regAliases){
    $basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
    $keyPath = $basePath + "\Explorer" 
    Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 0
}

# Explorer neu starten und die Layout-Datei löschen
Update-ProgressDialog "Starte den Explorer neu und lösche die Layout-Datei..."
Stop-Process -name explorer -Force
Import-StartLayout -LayoutPath $layoutFile -MountPath $env:SystemDrive\
Remove-Item $layoutFile -Force
    
Close-ProgressDialog "Startmenü-Icons wurden erfolgreich entfernt!"


    


