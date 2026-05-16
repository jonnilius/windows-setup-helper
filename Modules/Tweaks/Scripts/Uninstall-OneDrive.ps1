using namespace System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms

function Show-YesNoDialog {
    param(
        [string]$Message,
        [string]$Title = "Bestätigung"
        
    )
    $result = [MessageBox]::Show($Message, $Title, [MessageBoxButtons]::YesNo, [MessageBoxIcon]::Question)
    return $result -eq [DialogResult]::Yes
}

# Bestätigungsdialog anzeigen
$confirm = Show-YesNoDialog -Message "Möchten Sie OneDrive wirklich deinstallieren?" -Title "OneDrive Deinstallation"
if (-not $confirm) { & $ShowText "OneDrive-Deinstallation abgebrochen."; return }

# Fortschrittsmeldung anzeigen
Show-ProgressDialog "Entferne OneDrive..."


# OneDrive-Ordner überprüfen und ggf. sichern
Update-ProgressDialog "Entferne OneDrive" "Überprüfe OneDrive-Ordner..."
if (Test-Path "$env:USERPROFILE\OneDrive\*") {
    Update-ProgressDialog "Entferne OneDrive" "OneDrive-Ordner ist nicht leer..."

    $confirm = Show-YesNoDialog -Message "Der OneDrive-Ordner enthält Dateien. Möchten Sie diese sichern, bevor OneDrive deinstalliert wird?" -Title "OneDrive-Ordner nicht leer"
    if ($confirm) { 
        # Backup-Ordner auf dem Desktop erstellen, falls er nicht existiert
        Update-ProgressDialog "Entferne OneDrive" "Sichere Dateien..."

        # Überprüfen, ob der Backup-Ordner bereits existiert, und gegebenenfalls erstellen
        if (!(Test-Path "$env:USERPROFILE\Desktop\OneDriveBackupFiles")) {
            Update-ProgressDialog "Entferne OneDrive" "Erstelle Ordner 'OneDriveBackupFiles' auf dem Desktop..."
            New-Item -Path "$env:USERPROFILE\Desktop" -Name "OneDriveBackupFiles" -ItemType Directory -Force
        }

        # OneDrive-Ordnerinhalt in den Backup-Ordner verschieben
        Update-ProgressDialog "Entferne OneDrive" "Verschiebe Dateien in den Ordner 'OneDriveBackupFiles' auf dem Desktop..."
        Move-Item -Path "$env:USERPROFILE\OneDrive\*" -Destination "$env:USERPROFILE\Desktop\OneDriveBackupFiles" -Force

        # Abschließende Meldung anzeigen
        Update-ProgressDialog "Entferne OneDrive" "Alle Dateien wurden in den Ordner 'OneDriveBackupFiles' auf dem Desktop verschoben."
    } else { Update-ProgressDialog "Entferne OneDrive" "OneDrive-Ordner wird nicht gesichert. Fahre mit der Deinstallation fort..." }
} else { Update-ProgressDialog "Entferne OneDrive" "OneDrive-Ordner ist leer. Fahre mit der Deinstallation fort..." }

# OneDrive-Pfade und -Informationen erfassen
Update-ProgressDialog "Entferne OneDrive" "Erfasse OneDrive-Informationen..."
New-PSDrive  HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue | Out-Null
$OneDrive       = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
$ExplorerReg1   = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
$ExplorerReg2   = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"

# OneDrive-Prozesse beenden
Update-ProgressDialog "Entferne OneDrive" "Beende OneDrive-Prozesse..."
Stop-Process -Name "OneDrive*" -ErrorAction SilentlyContinue
Stop-Process -Name "Microsoft OneDriveFile*" -ErrorAction SilentlyContinue

# Richtige OneDrive-Setup-Datei ermitteln und deinstallieren
Update-ProgressDialog "Entferne OneDrive" "Starte OneDrive-Deinstallation..."
If (!(Test-Path $OneDrive)) { $OneDrive = "$env:SYSTEMROOT\System32\OneDriveSetup.exe" }
Start-Process $OneDrive "/uninstall" -NoNewWindow -Wait

# Datei-Explorer beenden
Update-ProgressDialog "Entferne OneDrive" "Beende Datei-Explorer..."
Stop-Process -Name explorer -Force
# taskkill.exe /F /IM explorer.exe
Start-Sleep -Seconds 3

# Verbleibende Dateien entfernen
Update-ProgressDialog "Entferne OneDrive" "Entferne verbleibende Dateien..."
Remove-Item "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
If (Test-Path "$env:SYSTEMDRIVE\OneDriveTemp") { Remove-Item "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse -ErrorAction SilentlyContinue }

# OneDrive aus dem Windows Explorer entfernen
Update-ProgressDialog "Entferne OneDrive" "Entferne OneDrive aus dem Windows Explorer..."
If (!(Test-Path $ExplorerReg1)) { New-Item $ExplorerReg1 }
Set-ItemProperty $ExplorerReg1 System.IsPinnedToNameSpaceTree -Value 0 
If (!(Test-Path $ExplorerReg2)) { New-Item $ExplorerReg2 }
Set-ItemProperty $ExplorerReg2 System.IsPinnedToNameSpaceTree -Value 0

# Starte den zuvor beendeten Explorer neu
Update-ProgressDialog "Entferne OneDrive" "Starte den zuvor beendeten Explorer neu..."
Start-Process explorer.exe -NoNewWindow

# Aktiviere die Gruppenrichtlinie 'Verweigern der Verwendung von OneDrive für die Dateispeicherung'
Update-ProgressDialog "Entferne OneDrive" "Aktiviere die Gruppenrichtlinie 'Verweigern der Verwendung von OneDrive für die Dateispeicherung'..."
$OneDriveKey = 'HKLM:Software\Policies\Microsoft\Windows\OneDrive'
If (!(Test-Path $OneDriveKey)) { New-Item -Path $OneDriveKey -ItemType Directory -Force | Out-Null }
Set-ItemProperty $OneDriveKey -Name OneDrive -Value DisableFileSyncNGSC -Type DWord -Force

# Abschließende Meldung anzeigen
Close-ProgressDialog "Entferne OneDrive" "OneDrive wurde erfolgreich deinstalliert!"


