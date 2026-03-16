using namespace System.Windows.Forms
using namespace System.Drawing

function Update-StatusLabel {
    param( 
        [System.Windows.Forms.Label]$Label, 
        [string]$Message,
        [int]$DelaySeconds = 2
    )

    # Stelle sicher, dass das Label sichtbar ist, bevor der Text aktualisiert wird, damit die Benutzer den Fortschritt sehen können.
    if ($Label.Visible -eq $false) { $Label.Visible = $true }

    # Überprüfen Sie, ob der Aufruf von einem anderen Thread als dem UI-Thread stammt, und verwenden Sie Invoke, um den Text sicher zu aktualisieren.
    if ($Label.InvokeRequired) {
        $Label.Invoke({ param($l, $m, $d) Update-StatusLabel -Label $l -Message $m -DelaySeconds $d }, $Label, $Message, $DelaySeconds)
        return
    }

    # Optionaler Delay, um sicherzustellen, dass Benutzer den Fortschritt sehen können, bevor der Text aktualisiert wird.
    if ($DelaySeconds -gt 0) { Start-Sleep -Seconds $DelaySeconds }

    $Label.Text = $Message
    [System.Windows.Forms.Application]::DoEvents()
}

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
}
function Hide-StartMenuIcons {
    param( $TextForm )

    $TextForm.Visible = $true
    $TextForm.Text = "Entferne Startmenü-Icons...`n"
    Start-Sleep -Seconds 1


    # Definiere Startmenü-Layout als XML-String
    $TextForm.Text += "Definiere ein Startmenü-Layout`n"
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
    $TextForm.Text += "Startmenü-Layout zuweisen und Anwendung erzwingen...`n"
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
    $TextForm.Text += "Starte den Explorer neu...`n"
    Stop-Process -name explorer
    Start-Sleep -Seconds 5
    $wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^{ESCAPE}')
    Start-Sleep -Seconds 5

    # Entfernen der Sperre, damit Benutzer das Startmenü-Layout wieder anpassen können, falls gewünscht.
    $TextForm.Text += "Entferne die Sperre, damit Benutzer das Startmenü-Layout wieder anpassen können...`n"
    foreach ($regAlias in $regAliases){
        $basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
        $keyPath = $basePath + "\Explorer" 
        Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 0
    }
    Start-Sleep -Seconds 1
    

    # Explorer neu starten und die Layout-Datei löschen
    $TextForm.Text += "Starte den Explorer neu und lösche die Layout-Datei...`n"
    Stop-Process -name explorer
    Import-StartLayout -LayoutPath $layoutFile -MountPath $env:SystemDrive\
    Remove-Item $layoutFile
    Start-Sleep -Seconds 1

    $TextForm.Text += "Startmenü-Icons wurden erfolgreich entfernt!`n"
    $TextForm.Visible = $false
    Start-Sleep -Seconds 5
}

<# FORMS #>
function AboutForm {
    $Config = @{
        Properties = @{
            Text = "About - $($AppInfo.Name)"
            ClientSize = [Size]::new(350,400)
            Icon = Get-Icon "About"
            FormBorderStyle = "FixedDialog"
            KeyPreview = $true
        }
        Controls = @{
            Panel = @{
                Control = "Panel"
                Padding = [Padding]::new(10)
                Controls = @{
                    FlowPanel = @{
                        Control = "FlowLayoutPanel"
                        WrapContents = $false
                        Dock = "Fill"
                        Controls = [ordered]@{
                            Label = @{
                                Control = "Label"
                                Text = "WINDOWS SETUP HELPER"
                                ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
                                Dock = "Fill"
                                TextAlign = "MiddleCenter"
                                Margin = [Padding]::new(0,10,0,10)
                                Font = [Font]::new("Consolas", 20 )
                            }
                            RichText = @{
                                Control = "RichTextBox"
                                Size    = [Size]::new(310,310)
                                Text    = @"
Windows Setup Helper ist ein PowerShell-Skript, das die Einrichtung und Grundkonfiguration eines Windows-Systems deutlich vereinfacht.`n
Mit einer übersichtlichen grafischen Oberfläche ermöglicht es die schnelle Installation und Verwaltung von Programmen über Chocolatey, das Ändern von Systemeinstellungen wie Gerätename oder Zeitserver sowie das Anzeigen wichtiger Systeminformationen.`n
Das Skript richtet sich an alle, die Windows-PCs effizient und wiederholbar einrichten möchten - egal ob für den privaten Gebrauch, im Unternehmen oder in Bildungseinrichtungen.`n
Durch die Integration von Automatisierung und Benutzerfreundlichkeit spart der Windows Setup Helper Zeit und reduziert Fehlerquellen bei der Systemeinrichtung.`n
Version: $($AppInfo.Version)
Entwickler: $($AppInfo.Author)
Lizenz: MIT
"@
                            }
                        }
                    }
                }
            }
        }
        Events = @{
            KeyDown = { if ($_.KeyCode -eq "Escape") { $this.Close() } }
        }
    }
    $Form  = New-Form $Config
    $Form.ShowDialog()
    $Form.Dispose()
}
function DebloatForm {
    param( $FormConfig )

    $Form = New-Form $FormConfig
    $Form.ShowDialog()
    $Form.Dispose()
}
function DeviceNameForm {    
    $Config = @{
        Properties = @{
            Text = "Neuer Gerätename"
            ClientSize  = [Size]::new(300,40)
            Padding     = [Padding]::new(5)
            FormBorderStyle = "FixedDialog"
            Icon = Get-Icon "DeviceName"
        }
        Controls = @{
            TableLayout = @{
                Control = "TableLayoutPanel"
                Dock = "Fill"
                Padding = [Padding]::new(0)
                ColumnCount = 2
                RowCount = 1
                ColumnStyles = @(
                    [System.Windows.Forms.ColumnStyle]::new("Percent", 100),
                    [System.Windows.Forms.ColumnStyle]::new("AutoSize")
                )
                RowStyles = @(
                    [System.Windows.Forms.RowStyle]::new("Percent", 100)
                )
                Controls = @{
                    TextBox = @{
                        Control = "TextBox"
                        Font = [Font]::new("Consolas", 15)
                        # Width = 200
                        ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
                        BackColor = [ColorTranslator]::FromHtml($Colors.Dark)
                        TextAlign = "Center"
                        BorderStyle = "None"
                        Text = $env:COMPUTERNAME
                        Multiline = $false
                    }
                    Button = @{
                        Control = "Button"
                        Text = "Ändern"
                        Size = [Size]::new(100,25)
                        FlatStyle = "Flat"
                        TextAlign = "MiddleCenter"
                        BackColor = [ColorTranslator]::FromHtml($Colors.Dark)
                        ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
                        Add_Click = { ChangeDeviceName -NewName $this.Controls["TextBox"].Text }
                    }
                }
            }
        }
        Events = @{
            Shown = { $this.Controls["Button"].Focus() }
        }
    }
    $Form = New-Form $Config
    $Form.ShowDialog()
}