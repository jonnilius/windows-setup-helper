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
function RemoveOneDrive {
    # Erstelle das Formular
    $Form = New-Object System.Windows.Forms.Form
    $Form.ClientSize = New-Object System.Drawing.Size(300,100)
    $Form.Padding = New-Object System.Windows.Forms.Padding(10)
    $Form.StartPosition = "CenterScreen"
    $Form.Text = "Entferne OneDrive..."
    $Form.BackColor = [ColorTranslator]::FromHtml("#C0393B")

    # Erstelle ein Panel
    $Panel = New-Object System.Windows.Forms.Panel
    $Panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $Panel.BackColor = [ColorTranslator]::FromHtml("#2D3436")
    $Form.Controls.Add($Panel)

    # Erstelle ein Label
    $Label = New-Object System.Windows.Forms.Label
    $Label.Dock = [System.Windows.Forms.DockStyle]::Fill
    $Label.TextAlign = [ContentAlignment]::MiddleCenter
    $Label.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $Label.Text = "OneDrive wird entfernt. Bitte warten..."
    $Panel.Controls.Add($Label)

    # Zeige das Formular an
    $Form.Show()

    # OneDrive überprüfen
    $Label.Text = "Überprüfe OneDrive-Ordner..."
    if (Test-Path "$env:USERPROFILE\OneDrive\*") {
        $Label.Text = "OneDrive-Ordner ist nicht leer..."
        Start-Sleep -Seconds 1

        $confirm = [System.Windows.Forms.MessageBox]::Show("Der OneDrive-Ordner enthält Dateien. Möchten Sie diese sichern, bevor OneDrive deinstalliert wird?", "OneDrive-Ordner nicht leer", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) { 
            # Backup-Ordner auf dem Desktop erstellen, falls er nicht existiert
            $Label.Text = "Sichere Dateien..."
            if (!(Test-Path "$env:USERPROFILE\Desktop\OneDriveBackupFiles")) {
                $Label.Text = "Erstelle Ordner 'OneDriveBackupFiles' auf dem Desktop. Alle Dateien werden in diesen Ordner verschoben."
                New-Item -Path "$env:USERPROFILE\Desktop" -Name "OneDriveBackupFiles" -ItemType Directory -Force
                Start-Sleep -Seconds 1
            }

            # OneDrive-Ordnerinhalt in den Backup-Ordner verschieben
            Move-Item -Path "$env:USERPROFILE\OneDrive\*" -Destination "$env:USERPROFILE\Desktop\OneDriveBackupFiles" -Force
            $Label.Text = "Alle Dateien wurden in den Ordner 'OneDriveBackupFiles' auf dem Desktop verschoben."
            Start-Sleep -Seconds 1
        } else {
            $Label.Text = "OneDrive-Ordner wird nicht gesichert. `nFahre mit der Deinstallation fort..."
            Start-Sleep -Seconds 1
        }
    } else {
        $Label.Text = "OneDrive-Ordner ist leer..."
        Start-Sleep -Seconds 1
    }

    # OneDrive deinstallieren
    $Label.Text = "Erfasse OneDrive-Informationen..."
    New-PSDrive  HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    $OneDrive = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
    $ExplorerReg1 = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    $ExplorerReg2 = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"

    # OneDrive-Prozesse beenden
    $Label.Text = "Beende OneDrive-Prozesse..."
    Stop-Process -Name "OneDrive*"
    Stop-Process -Name "Microsoft OneDriveFile*"
    Start-Sleep -Seconds 2

    # Richtige OneDrive-Setup-Datei ermitteln und deinstallieren
    If (!(Test-Path $OneDrive)) { $OneDrive = "$env:SYSTEMROOT\System32\OneDriveSetup.exe" }
    Start-Process $OneDrive "/uninstall" -NoNewWindow -Wait
    Start-Sleep -Seconds 2

    # Datei-Explorer beenden
    $Label.Text = "Beende Datei-Explorer..."
    Start-Sleep -Seconds 1
    taskkill.exe /F /IM explorer.exe
    Start-Sleep -Seconds 3

    # Verbleibende Dateien entfernen
    $Label.Text = "Entferne verbleibende Dateien..."
    Remove-Item "$env:USERPROFILE\OneDrive" -Force -Recurse
    Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse
    Remove-Item "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse
    If (Test-Path "$env:SYSTEMDRIVE\OneDriveTemp") { Remove-Item "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse }
    Start-Sleep -Seconds 1

    # OneDrive aus dem Windows Explorer entfernen
    $Label.Text = "Entferne OneDrive aus dem Windows Explorer..."
    If (!(Test-Path $ExplorerReg1)) { New-Item $ExplorerReg1 }
    Set-ItemProperty $ExplorerReg1 System.IsPinnedToNameSpaceTree -Value 0 
    If (!(Test-Path $ExplorerReg2)) { New-Item $ExplorerReg2 }
    Set-ItemProperty $ExplorerReg2 System.IsPinnedToNameSpaceTree -Value 0
    Start-Sleep -Seconds 1

    # Starte den zuvor beendeten Explorer neu
    $Label.Text = "Starte den zuvor beendeten Explorer neu..."
    Start-Process explorer.exe -NoNewWindow
    Start-Sleep -Seconds 2

    # Aktiviere die Gruppenrichtlinie 'Verweigern der Verwendung von OneDrive für die Dateispeicherung'
    $Label.Text = "Aktiviere die Gruppenrichtlinie 'Verweigern der Verwendung von OneDrive für die Dateispeicherung'..."
    $OneDriveKey = 'HKLM:Software\Policies\Microsoft\Windows\OneDrive'
    If (!(Test-Path $OneDriveKey)) { Mkdir $OneDriveKey }
    Set-ItemProperty $OneDriveKey -Name OneDrive -Value DisableFileSyncNGSC
    Start-Sleep -Seconds 1

    # Abschließende Meldung anzeigen
    $Label.Text = "OneDrive wurde erfolgreich deinstalliert!"
    Start-Sleep -Seconds 2


    # Fenster schließen
    $Form.Close()
    $Form.Dispose()
}
function UnpinStartMenuIcons {
    # Erstelle das Formular
    $Form = New-Object System.Windows.Forms.Form
    $Form.ClientSize = New-Object System.Drawing.Size(300,120)
    $Form.Padding = New-Object System.Windows.Forms.Padding(10)
    $Form.StartPosition = "CenterScreen"
    $Form.Text = "Startmenü-Icons entfernen..."
    $Form.BackColor = [ColorTranslator]::FromHtml("#C0393B")

    # Erstelle ein Panel
    $Panel = New-Object System.Windows.Forms.Panel
    $Panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $Panel.BackColor = [ColorTranslator]::FromHtml("#2D3436")
    $Form.Controls.Add($Panel)

    # Erstelle ein Label
    $Label = New-Object System.Windows.Forms.Label
    $Label.Dock = [System.Windows.Forms.DockStyle]::Fill
    $Label.TextAlign = [ContentAlignment]::MiddleCenter
    $Label.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $Label.Text = "Startmenü-Icons werden entfernt. Bitte warten..."
    $Panel.Controls.Add($Label)

    # Fenster anzeigen
    $Form.Show()

    # Definiere Startmenü-Layout als XML-String
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
    $layoutFile="C:\Windows\StartMenuLayout.xml"

    # Lösche die Layout-Datei, falls sie bereits existiert
    If ( Test-Path $layoutFile ) { Remove-Item $layoutFile }

    # Erstelle die neue Layout-Datei mit dem definierten XML-Layout
    $START_MENU_LAYOUT | Out-File $layoutFile -Encoding ASCII

    $regAliases = @("HKLM", "HKCU")

    # Weisen Sie das Startlayout zu und erzwingen Sie die Anwendung mit "LockedStartLayout" sowohl auf Maschinen- als auch auf Benutzerebene
    foreach ($regAlias in $regAliases){
        $basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
        $keyPath = $basePath + "\Explorer" 
        IF(!(Test-Path -Path $keyPath)) { 
            New-Item -Path $basePath -Name "Explorer"
        }
        Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 1
        Set-ItemProperty -Path $keyPath -Name "StartLayoutFile" -Value $layoutFile
    }

    # Explorer neu starten, damit die Änderungen wirksam werden. 
    # Das Startmenü-Layout wird nun auf das definierte XML-Layout gesetzt, und die Benutzer können keine Änderungen daran vornehmen.
    Stop-Process -name explorer
    Start-Sleep -Seconds 5
    $wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^{ESCAPE}')
    Start-Sleep -Seconds 5

    # Entfernen der Sperre, damit Benutzer das Startmenü-Layout wieder anpassen können, falls gewünscht.
    foreach ($regAlias in $regAliases){
        $basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
        $keyPath = $basePath + "\Explorer" 
        Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 0
    }

    # Explorer neu starten und die Layout-Datei löschen
    Stop-Process -name explorer

    # Das neue Startmenü-Layout wird sofort angewendet, und die Benutzer können es nach dem Neustart des Explorers anpassen, wenn sie möchten.
    Import-StartLayout -LayoutPath $layoutFile -MountPath $env:SystemDrive\
    Remove-Item $layoutFile

    # Abschließende Meldung anzeigen
    $Label.Text = "Startmenü-Icons wurden erfolgreich entfernt!"
    Start-Sleep -Seconds 5

    # Fenster schließen
    $Form.Close()
    $Form.Dispose()

}


<# DIALOGE #>
function DeviceName {
    param($FormConfig)
    
    $Form = New-Form $FormConfig.DeviceName

    $Panel = New-Control $FormConfig.DeviceName.Controls.TableLayout


    $Form.Controls.Add($Panel)
    
    # Textbox
    $TextBox = [TextBox]::new()
    $TextBox.Font = [Font]::new("Consolas", 15)
    $TextBox.Width = 200
    $TextBox.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $TextBox.BackColor = [ColorTranslator]::FromHtml("#2D3436")
    $TextBox.TextAlign = "Center"
    $TextBox.BorderStyle = "None"
    $TextBox.Text = $env:COMPUTERNAME
    $TextBox.Multiline = $false
    $Panel.Controls.Add($TextBox)
    
    # Button 
    $Button = New-Object System.Windows.Forms.Button
    $Button.Text = "Ändern"
    $Button.Width = 100
    $Button.Height = 25
    $Button.FlatStyle = "Flat"
    $Button.TextAlign = "MiddleCenter"
    $Button.BackColor = [ColorTranslator]::FromHtml("#2D3436")
    $Button.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $Panel.Controls.Add($Button)
    $Button.Add_Click({ ChangeDeviceName -NewName $TextBox.Text })
    $Form.Add_Shown({ $Button.Focus() })

    $Form.ShowDialog()
}
function AboutForm {
    param([hashtable]$FormConfig)
    $Form  = New-Form $FormConfig.About
    # $Form  = New-Form -FormName "About"
    $Panel = New-Panel $FormConfig.Panel.About
    
    $Form.Controls.Add($Panel)

    $FlowPanel = New-FlowLayoutPanel "About"
    $Panel.Controls.Add($FlowPanel)

    # Erstelle die Header-Label
    $Header = New-Object System.Windows.Forms.Label
    $Header.Text = "Windows Setup Helper"
    $Header.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $Header.Dock = "Fill"
    $Header.TextAlign = "MiddleCenter"
    $Header.Margin = New-Object System.Windows.Forms.Padding(0,10,0,10)
    $Header.Font = New-Object System.Drawing.Font("Consolas", 19)
    $FlowPanel.Controls.Add($Header)

    # Erstelle die Textbox
    $Text = New-RichTextBox "About"
    $FlowPanel.Controls.Add($Text)

    # Zeige das Formular an
    $Form.ShowDialog()
}
function DebloatForm {
    param($FormConfig)
    $Form = New-Form $FormConfig.Debloat.Properties
    $Panel = New-Panel $FormConfig.Panel.Debloat
    
    $Form.Controls.Add($Panel)

    # Erstelle das FlowLayoutPanel
    $FlowPanel = New-FlowLayoutPanel "Debloat"
    $Panel.Controls.Add($FlowPanel)

    # Erstelle die Buttons
    $RemoveOneDriveButton = New-Object System.Windows.Forms.Button
    $RemoveOneDriveButton.Text = "OneDrive entfernen"
    $RemoveOneDriveButton.Size = New-Object System.Drawing.Size(200,25)
    $RemoveOneDriveButton.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $RemoveOneDriveButton.BackColor = [ColorTranslator]::FromHtml("#2D3436")
    $RemoveOneDriveButton.FlatStyle = "Flat"
    $FlowPanel.Controls.Add($RemoveOneDriveButton)

    $UnpinStartMenuButton = New-Object System.Windows.Forms.Button
    $UnpinStartMenuButton.Text = "Startmenü-Icons entfernen"
    $UnpinStartMenuButton.Size = New-Object System.Drawing.Size(200,25)
    $UnpinStartMenuButton.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $UnpinStartMenuButton.BackColor = [ColorTranslator]::FromHtml("#2D3436")
    $UnpinStartMenuButton.FlatStyle = "Flat"
    $FlowPanel.Controls.Add($UnpinStartMenuButton)

    $ChangeDeviceNameButton = New-Object System.Windows.Forms.Button
    $ChangeDeviceNameButton.Text = "Gerätename ändern"
    $ChangeDeviceNameButton.Size = New-Object System.Drawing.Size(200,25)
    $ChangeDeviceNameButton.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
    $ChangeDeviceNameButton.BackColor = [ColorTranslator]::FromHtml("#2D3436")
    $ChangeDeviceNameButton.FlatStyle = "Flat"
    $FlowPanel.Controls.Add($ChangeDeviceNameButton)

    # Button-Eventhandler hinzufügen
    $RemoveOneDriveButton.Add_Click( { RemoveOneDrive } )
    $UnpinStartMenuButton.Add_Click( { UnpinStartMenuIcons } )
    $ChangeDeviceNameButton.Add_Click( { DeviceName $FormConfig } )

    # Zeige das Formular an
    $Form.ShowDialog()
}