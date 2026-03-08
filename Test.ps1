using namespace System.Windows.Forms
using namespace System.Drawing

function New-Form {
    [CmdletBinding()]
    param( [hashtable]$FormConfig = @{} )

    # Form erstellen und Standardwerte setzen
    Write-Verbose "Form wird erstellt..."
    try {
        $form = [Form]::new()
        $form.StartPosition = "CenterScreen"
        $form.BackColor = [ColorTranslator]::FromHtml("#C0393B")
        $form.ForeColor = [ColorTranslator]::FromHtml("#2D3436") 
        $form.Padding = [Padding]::new(10)
        $form.MaximizeBox = $false
        $form.FormBorderStyle = "FixedSingle"
        $form.Text = "Form ohne Titel"
        # $form.Icon = Get-Icon "Default"
    }
    catch {
        Write-Error "Fehler beim Erstellen des Formulars: $_"
        return $null
    }
    
    # Debug-Informationen zu Form-Eigenschaften und -Ereignissen
    $props = $form.PSObject.Properties.Name
    Write-Verbose "Form-Eigenschaften: $($props -join ', ')"
    $events = $form.GetType().GetEvents().Name
    Write-Verbose "Form-Ereignisse: $($events -join ', ')"
    
    # Form-Konfigurationen anwenden
    Write-Verbose "Form-Konfigurationen werden angewendet..."
    foreach ($key in $FormConfig.Keys) {
        Write-Verbose "Verarbeite Key: $key"
        $name = $key

        if ($key -like "Add_*"){ 
            $name = $key.Substring(4) 
            if ($events -contains $name) { 
                Write-Verbose "Füge Ereignis-Handler hinzu: $name"
                $form.$key($FormConfig[$key])
            } else {
                Write-Verbose "Ungültiges Ereignis: $name"
            }
        } elseif ($key -like "Remove_*"){ 
            $name = $key.Substring(7) 
            if ($events -contains $name) { 
                Write-Verbose "Entferne Ereignis-Handler: $name"
                $form.$key($FormConfig[$key])
            } else {
                Write-Verbose "Ungültiges Ereignis: $name"
            }
        } elseif ($form.PSObject.Properties.Match($key)) { 
            Write-Verbose "Setze Eigenschaft: $key"
            $form.$key = $FormConfig[$key] 
        } else { 
            Write-Verbose "Ungültige Form-Konfiguration: $key" 
        }
    }

    # Form zurückgeben
    return $form
}
$FormConfig = @{
    Form = @{
        # Beim Hinzufügen von Events bezieht sich $this auf das jeweilige Form-Objekt
        Main = @{
            Text        = "$($AppInfo.Name) $($AppInfo.Version)"
            Icon        = Get-Icon "Main"
            ClientSize  = [Size]::new(400,565)
        }
        Chocolatey = @{
            Text        = "$($AppInfo.Name) - Chocolatey"
            Icon        = Get-Icon "Chocolatey"
            ClientSize  = [Size]::new(600,300)
        }
        About = @{
            Text        = "About $($AppInfo.Name)"
            Icon        = Get-Icon "About"
            ClientSize        = [Size]::new(350,400)
            FormBorderStyle = "FixedDialog"
            KeyPreview   = $true
            Add_KeyDown = { if ($_.KeyCode -eq "Escape") { $this.Close() } }
        }
        Debloat = @{
            Text        = "Tweaks & Debloat"
            Icon            = Get-Icon "Debloat"
            ClientSize      = [Size]::new(245,125)
            FormBorderStyle = "FixedDialog"
        }
        DeviceName = @{
            Text        = "Gerätename festlegen"
            Icon        = Get-Icon "DeviceName"
            ClientSize        = [Size]::new(300,60)
            Padding = [Padding]::new(5)
            FormBorderStyle = "FixedDialog"
        }
    }
    Button = @{
        ChocoListInstall = @{
            Text = "INSTALLIEREN"
            Font = [Font]::new("Consolas", 8)
            Dock = "Bottom"
        }
        ChocoListMore = @{
            Text = ("Chocolatey verwalten").ToUpper()
            Font = [Font]::new("Consolas", 8)
            Dock = "Bottom"
        }
        UninstallChoco = @{ 
            Text = "Chocolatey entfernen"
            Size = [Size]::new(190,25)
            Location = [Point]::new(10,35)
            Font = [Font]::new("Consolas", 8, [FontStyle]::Bold)
            Dock = "Bottom"
            BackColor = [ColorTranslator]::FromHtml("#2D3436")
            ForeColor = [ColorTranslator]::FromHtml("#C0393B")
            Add_Click = { 
                $confirm = [System.Windows.Forms.MessageBox]::Show("Möchten Sie Chocolatey wirklich entfernen?", "Bestätigung", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
                if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) { return }
                
                # $Form.Cursor = [Cursors]::AppStarting
                
                Start-Sleep -Seconds 1
                Uninstall-Chocolatey | Out-Null
                # $Main.Cursor = [Cursors]::Default
                Start-Sleep -Seconds 1
                [System.Windows.Forms.MessageBox]::Show("Chocolatey wurde erfolgreich entfernt.", "Erfolg", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
             }
        }
    }
    Label = @{
        ChocoListLabel = @{
            Text = "Wählen Sie die Programme aus, die Sie installieren möchten:"
            Font = [Font]::new("Consolas", 9, [FontStyle]::Italic)
            Dock = "Top"
            AutoSize = $false
            TextAlign = "MiddleCenter"
        }
        PackageLabel = @{
            Text = "INSTALLIERT"
            ForeColor = [ColorTranslator]::FromHtml("#EEEEEE")
            AutoSize = $true
            Location = [Point]::new(10,10)
            Font = [Font]::new("Consolas", 13, ([FontStyle]::Bold -bor [FontStyle]::Underline))
        }
    }
    Panel = @{
        About = @{
            Padding = [Padding]::new(10)
        }
        DeviceName = @{
            Padding = [Padding]::new(10)
        }
        Debloat = @{
            Padding = [Padding]::new(10,5,10,5)
        }
        Chocolatey = @{
            Padding = [Padding]::new(10)
            ForeColor = [ColorTranslator]::FromHtml("#C0393B")
        }
        Header = @{
            Height = 50
            Dock = "Top"
            BackColor = [ColorTranslator]::FromHtml("#C0393B")
        }
        Footer = @{
            Height = 15
            Dock = "Bottom"
            BackColor = [ColorTranslator]::FromHtml("#C0393B")
        }
        Sidebar = @{
            Dock = "Right"
            BackColor = [ColorTranslator]::FromHtml("#C0393B")
            Padding = [Padding]::new(10,5,0,0)
        }
        Space = @{
            Dock = "Fill"
            BackColor = [ColorTranslator]::FromHtml("#EEEEEE")
            Height = 10
        }
    }
}


    
$Form = New-Form $FormConfig.Form.DeviceName
$Form.Add_Shown({ $Button.Focus() })

# Textbox
$TextBox = [TextBox]::new()
$TextBox.Font = [Font]::new("Consolas", 15)
$TextBox.Dock = "Top"
$TextBox.AutoSize = $false
$TextBox.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
$TextBox.BackColor = [ColorTranslator]::FromHtml("#2D3436")
$TextBox.TextAlign = "Center"
$TextBox.BorderStyle = "None"
$TextBox.Text = $env:COMPUTERNAME
$TextBox.Multiline = $false
$TextBox.Padding = New-Object System.Windows.Forms.Padding(10,10,0,0)
$Form.Controls.Add($TextBox)

# Space
# $Space = New-Object System.Windows.Forms.Label
# $Space.Text = " "
# $Space.Height = 10
# $Form.Controls.Add($Space)

# Button 
$Button = New-Object System.Windows.Forms.Button
$Button.Text = "Ändern"
$Button.Width = 100
$Button.Dock = "Right"
$Button.FlatStyle = "Flat"
$Button.BackColor = [ColorTranslator]::FromHtml("#2D3436")
$Button.ForeColor = [ColorTranslator]::FromHtml("#C0393B")
$Form.Controls.Add($Button)
$Button.Add_Click({ ChangeDeviceName -NewName $TextBox.Text })

$Form.ShowDialog()
