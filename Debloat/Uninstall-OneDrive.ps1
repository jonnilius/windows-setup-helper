
    param( $form )

    $TextForm.Text = "Entferne OneDrive...`n"
    Start-Sleep -Seconds 2

    # OneDrive überprüfen
    $TextForm.Text += "Überprüfe OneDrive-Ordner...`n"
    if (Test-Path "$env:USERPROFILE\OneDrive\*") {
        $TextForm.Text += "OneDrive-Ordner ist nicht leer...`n"
        Start-Sleep -Seconds 1

        $confirm = [System.Windows.Forms.MessageBox]::Show("Der OneDrive-Ordner enthält Dateien. Möchten Sie diese sichern, bevor OneDrive deinstalliert wird?", "OneDrive-Ordner nicht leer", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) { 
            # Backup-Ordner auf dem Desktop erstellen, falls er nicht existiert
            $TextForm.Text += "Sichere Dateien...`n"
            if (!(Test-Path "$env:USERPROFILE\Desktop\OneDriveBackupFiles")) {
                $TextForm.Text += "Erstelle Ordner 'OneDriveBackupFiles' auf dem Desktop. Alle Dateien werden in diesen Ordner verschoben.`n"
                New-Item -Path "$env:USERPROFILE\Desktop" -Name "OneDriveBackupFiles" -ItemType Directory -Force
                Start-Sleep -Seconds 1
            }

            # OneDrive-Ordnerinhalt in den Backup-Ordner verschieben
            Move-Item -Path "$env:USERPROFILE\OneDrive\*" -Destination "$env:USERPROFILE\Desktop\OneDriveBackupFiles" -Force
            $TextForm.Text += "Alle Dateien wurden in den Ordner 'OneDriveBackupFiles' auf dem Desktop verschoben.`n"
            Start-Sleep -Seconds 1
        } else {
            $TextForm.Text += "OneDrive-Ordner wird nicht gesichert. `nFahre mit der Deinstallation fort..."

            Start-Sleep -Seconds 1
        }
    } else {
        $TextForm.Text += "OneDrive-Ordner ist leer...`n"
        Start-Sleep -Seconds 1
    }

    # OneDrive deinstallieren
    $TextForm.Text += "Erfasse OneDrive-Informationen...`n"
    New-PSDrive  HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    $OneDrive = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
    $ExplorerReg1 = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    $ExplorerReg2 = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"

    # OneDrive-Prozesse beenden
    $TextForm.Text += "Beende OneDrive-Prozesse...`n"
    Stop-Process -Name "OneDrive*"
    Stop-Process -Name "Microsoft OneDriveFile*"
    Start-Sleep -Seconds 2

    # Richtige OneDrive-Setup-Datei ermitteln und deinstallieren
    If (!(Test-Path $OneDrive)) { $OneDrive = "$env:SYSTEMROOT\System32\OneDriveSetup.exe" }
    Start-Process $OneDrive "/uninstall" -NoNewWindow -Wait
    Start-Sleep -Seconds 2

    # Datei-Explorer beenden
    $TextForm.Text += "Beende Datei-Explorer...`n"
    Start-Sleep -Seconds 1
    taskkill.exe /F /IM explorer.exe
    Start-Sleep -Seconds 3

    # Verbleibende Dateien entfernen
    $TextForm.Text += "Entferne verbleibende Dateien...`n"
    Remove-Item "$env:USERPROFILE\OneDrive" -Force -Recurse
    Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse
    Remove-Item "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse
    If (Test-Path "$env:SYSTEMDRIVE\OneDriveTemp") { Remove-Item "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse }
    Start-Sleep -Seconds 1

    # OneDrive aus dem Windows Explorer entfernen
    $TextForm.Text += "Entferne OneDrive aus dem Windows Explorer...`n"
    If (!(Test-Path $ExplorerReg1)) { New-Item $ExplorerReg1 }
    Set-ItemProperty $ExplorerReg1 System.IsPinnedToNameSpaceTree -Value 0 
    If (!(Test-Path $ExplorerReg2)) { New-Item $ExplorerReg2 }
    Set-ItemProperty $ExplorerReg2 System.IsPinnedToNameSpaceTree -Value 0
    Start-Sleep -Seconds 1

    # Starte den zuvor beendeten Explorer neu
    $TextForm.Text += "Starte den zuvor beendeten Explorer neu...`n"
    Start-Process explorer.exe -NoNewWindow
    Start-Sleep -Seconds 2

    # Aktiviere die Gruppenrichtlinie 'Verweigern der Verwendung von OneDrive für die Dateispeicherung'
    $TextForm.Text += "Aktiviere die Gruppenrichtlinie 'Verweigern der Verwendung von OneDrive für die Dateispeicherung'...`n"
    $OneDriveKey = 'HKLM:Software\Policies\Microsoft\Windows\OneDrive'
    If (!(Test-Path $OneDriveKey)) { Mkdir $OneDriveKey }
    Set-ItemProperty $OneDriveKey -Name OneDrive -Value DisableFileSyncNGSC
    Start-Sleep -Seconds 1

    # Abschließende Meldung anzeigen
    $TextForm.Text += "OneDrive wurde erfolgreich deinstalliert!`n"
    Start-Sleep -Seconds 2
