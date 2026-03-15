using namespace System.Windows.Forms
using namespace System.Drawing

<# TOOLS #>
function ChangeDeviceName {
    param (
        [string]$NewName
    )
    if ($NewName -eq "") {
        [System.Windows.Forms.MessageBox]::Show("Der Gerätename wurde nicht geändert!", "Fehler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    else {
        Rename-Computer -NewName $NewName -Force
        [System.Windows.Forms.MessageBox]::Show("Der Gerätename wurde erfolgreich geändert! `nIhr neuer Gerätename: $NewName", "Erfolg", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        [System.Windows.Forms.MessageBox]::Show("Der Computer muss neu gestartet werden, damit die Änderung wirksam wird!", "Neustart erforderlich", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
}
function Uninstall-OneDrive {
    param( $TextForm )

    $TextForm.Text = "Entferne OneDrive..."
    Start-Sleep -Seconds 2

    # OneDrive überprüfen
    $TextForm.Text = "Überprüfe OneDrive-Ordner..."
    if (Test-Path "$env:USERPROFILE\OneDrive\*") {
        $TextForm.Text = "OneDrive-Ordner ist nicht leer..."
        Start-Sleep -Seconds 1

        $confirm = [System.Windows.Forms.MessageBox]::Show("Der OneDrive-Ordner enthält Dateien. Möchten Sie diese sichern, bevor OneDrive deinstalliert wird?", "OneDrive-Ordner nicht leer", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) { 
            # Backup-Ordner auf dem Desktop erstellen, falls er nicht existiert
            $TextForm.Text = "Sichere Dateien..."
            if (!(Test-Path "$env:USERPROFILE\Desktop\OneDriveBackupFiles")) {
                $TextForm.Text = "Erstelle Ordner 'OneDriveBackupFiles' auf dem Desktop. Alle Dateien werden in diesen Ordner verschoben."
                New-Item -Path "$env:USERPROFILE\Desktop" -Name "OneDriveBackupFiles" -ItemType Directory -Force
                Start-Sleep -Seconds 1
            }

            # OneDrive-Ordnerinhalt in den Backup-Ordner verschieben
            Move-Item -Path "$env:USERPROFILE\OneDrive\*" -Destination "$env:USERPROFILE\Desktop\OneDriveBackupFiles" -Force
            $TextForm.Text = "Alle Dateien wurden in den Ordner 'OneDriveBackupFiles' auf dem Desktop verschoben."
            Start-Sleep -Seconds 1
        } else {
            $TextForm.Text = "OneDrive-Ordner wird nicht gesichert. `nFahre mit der Deinstallation fort..."
            Start-Sleep -Seconds 1
        }
    } else {
        $TextForm.Text = "OneDrive-Ordner ist leer..."
        Start-Sleep -Seconds 1
    }

    # OneDrive deinstallieren
    $TextForm.Text = "Erfasse OneDrive-Informationen..."
    New-PSDrive  HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    $OneDrive = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
    $ExplorerReg1 = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    $ExplorerReg2 = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"

    # OneDrive-Prozesse beenden
    $TextForm.Text = "Beende OneDrive-Prozesse..."
    Stop-Process -Name "OneDrive*"
    Stop-Process -Name "Microsoft OneDriveFile*"
    Start-Sleep -Seconds 2

    # Richtige OneDrive-Setup-Datei ermitteln und deinstallieren
    If (!(Test-Path $OneDrive)) { $OneDrive = "$env:SYSTEMROOT\System32\OneDriveSetup.exe" }
    Start-Process $OneDrive "/uninstall" -NoNewWindow -Wait
    Start-Sleep -Seconds 2

    # Datei-Explorer beenden
    $TextForm.Text = "Beende Datei-Explorer..."
    Start-Sleep -Seconds 1
    taskkill.exe /F /IM explorer.exe
    Start-Sleep -Seconds 3

    # Verbleibende Dateien entfernen
    $TextForm.Text = "Entferne verbleibende Dateien..."
    Remove-Item "$env:USERPROFILE\OneDrive" -Force -Recurse
    Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse
    Remove-Item "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse
    If (Test-Path "$env:SYSTEMDRIVE\OneDriveTemp") { Remove-Item "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse }
    Start-Sleep -Seconds 1

    # OneDrive aus dem Windows Explorer entfernen
    $TextForm.Text = "Entferne OneDrive aus dem Windows Explorer..."
    If (!(Test-Path $ExplorerReg1)) { New-Item $ExplorerReg1 }
    Set-ItemProperty $ExplorerReg1 System.IsPinnedToNameSpaceTree -Value 0 
    If (!(Test-Path $ExplorerReg2)) { New-Item $ExplorerReg2 }
    Set-ItemProperty $ExplorerReg2 System.IsPinnedToNameSpaceTree -Value 0
    Start-Sleep -Seconds 1

    # Starte den zuvor beendeten Explorer neu
    $TextForm.Text = "Starte den zuvor beendeten Explorer neu..."
    Start-Process explorer.exe -NoNewWindow
    Start-Sleep -Seconds 2

    # Aktiviere die Gruppenrichtlinie 'Verweigern der Verwendung von OneDrive für die Dateispeicherung'
    $TextForm.Text = "Aktiviere die Gruppenrichtlinie 'Verweigern der Verwendung von OneDrive für die Dateispeicherung'..."
    $OneDriveKey = 'HKLM:Software\Policies\Microsoft\Windows\OneDrive'
    If (!(Test-Path $OneDriveKey)) { Mkdir $OneDriveKey }
    Set-ItemProperty $OneDriveKey -Name OneDrive -Value DisableFileSyncNGSC
    Start-Sleep -Seconds 1

    # Abschließende Meldung anzeigen
    $TextForm.Text = "OneDrive wurde erfolgreich deinstalliert!"
    Start-Sleep -Seconds 2
}
function Hide-StartMenuIcons {
    param( $TextForm )

    $TextForm.Visible = $true
    $TextForm.Text = "Entferne Startmenü-Icons..."
    Start-Sleep -Seconds 1


    # Definiere Startmenü-Layout als XML-String
    $TextForm.Text = "Definiere ein Startmenü-Layout"
    $layoutFile="C:\Windows\StartMenuLayout.xml"
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
    Start-Sleep -Seconds 2

    
    # Weisen Sie das Startlayout zu und erzwingen Sie die Anwendung mit "LockedStartLayout" sowohl auf Maschinen- als auch auf Benutzerebene
    $TextForm.Text = "Startmenü-Layout zuweisen und Anwendung erzwingen..."
    $regAliases = @("HKLM", "HKCU")
    foreach ($regAlias in $regAliases){
        $basePath   = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
        $keyPath    = $basePath + "\Explorer" 

        if(!(Test-Path -Path $keyPath)) { New-Item -Path $basePath -Name "Explorer" }

        Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 1
        Set-ItemProperty -Path $keyPath -Name "StartLayoutFile" -Value $layoutFile
    }

    # Explorer neu starten, damit die Änderungen wirksam werden. 
    # Das Startmenü-Layout wird nun auf das definierte XML-Layout gesetzt, und die Benutzer können keine Änderungen daran vornehmen.
    $TextForm.Text = "Starte den Explorer neu..."
    Stop-Process -name explorer
    Start-Sleep -Seconds 5
    $wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^{ESCAPE}')
    Start-Sleep -Seconds 5

    # Entfernen der Sperre, damit Benutzer das Startmenü-Layout wieder anpassen können, falls gewünscht.
    Start-Sleep -Seconds 1
    foreach ($regAlias in $regAliases){
        $basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
        $keyPath = $basePath + "\Explorer" 
        Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 0
    }

    # Explorer neu starten und die Layout-Datei löschen
    $TextForm.Text = "Starte den Explorer neu und lösche die Layout-Datei..."
    Stop-Process -name explorer
    Import-StartLayout -LayoutPath $layoutFile -MountPath $env:SystemDrive\
    Remove-Item $layoutFile
    Start-Sleep -Seconds 1
    $TextForm.Text = "Startmenü-Icons wurden erfolgreich entfernt!"
    Start-Sleep -Seconds 5

    $TextForm.Visible = $false



}