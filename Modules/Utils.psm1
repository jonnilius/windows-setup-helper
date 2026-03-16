using namespace System.Windows.Forms
using namespace System.Drawing

function Update-Status {
    param( $Label, $Message, $Delay = 0 )
    if ($null -eq $Label) { return }

    # Stellt sicher, dass das Label sichtbar ist, bevor der Text aktualisiert wird.

    # Überprüfen, ob der Aufruf von einem anderen Thread stammt, und gegebenenfalls den Aufruf auf den UI-Thread verschieben.
    if ($Label.InvokeRequired) {
        $Label.Invoke({ 
            param($l, $m, $d, $f) 
            Update-Status -Label $l -Message $m -Delay $d -Final:$f
        }, $Label, $Message, $Delay, $final)
        return
    }

    # Verzögert die Aktualisierung des Labels, wenn ein Delay angegeben ist.
    Start-Sleep -Seconds $Delay
    $Label.Text = $Message
    [System.Windows.Forms.Application]::DoEvents()
    
    if ($Label.Visible -eq $false) { $Label.Visible = $true }
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



<# FORMS #>

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