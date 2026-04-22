function Show-TextInput {
    param( 
        [string]$Title              = "Eingabe", 
        [string]$Label              = "Bitte geben Sie einen Wert ein:", 
        [string]$DefaultValue       = "", 
        [string]$Icon               = "TextInput",
        [string]$OKButtonText       = "OK",
        [string]$CancelButtonText   = "Abbrechen"
    )

    $FormConfig = @{
        Properties = @{
            Text            = "$Title -only"
            ClientSize      = 300,100
            MinimizeBox     = $false
            MaximizeBox     = $false
            KeyPreview      = $true
            FormBorderStyle = "FixedDialog"
            Padding         = [Padding]::new(5)
            BackColor       = Get-Color "Dark"
            Icon            = $Icon
        }
        Controls = [ordered]@{
            GroupBox = @{
                Control     = "GroupBox"
                Text        = $Label
                Dock        = "Fill"
                Controls    = [ordered]@{
                    InputTable = @{
                        Control     = "TableLayoutPanel"
                        Dock        = "Fill"
                        Row         = @("100", 34)
                        Controls    = [ordered]@{
                            Input = @{
                                Control     = "TextBox"
                                Name        = "Input"
                                Text        = $DefaultValue
                                Margin     = [Padding]::new(5)
                                TextAlign   = "Center"
                            }
                            Buttons = @{
                                Control     = "TableLayoutPanel"
                                Column      = @("50", "50")
                                Margin      = [Padding]::new(20,0,20,0)
                                Controls    = [ordered]@{
                                    OkButton    = @{
                                        Control     = "Button"
                                        Name        = "OkButton"
                                        Text        = $OKButtonText
                                        Height      = 24
                                        Anchor      = "Top, Left, Right"
                                        AutoCellDock= $false
                                        DialogResult= "OK"
                                        Add_Click    = {
                                            $text = Get-Control $this "Input"
                                            if ($text.Text.Trim() -eq "") { [System.Media.SystemSounds]::Exclamation.Play() }
                                        }
                                    }
                                    CancelButton= @{
                                        Control     = "Button"
                                        Name        = "CancelButton"
                                        Text        = $CancelButtonText
                                        Height      = 24
                                        Anchor      = "Top, Left, Right"
                                        AutoCellDock= $false
                                        DialogResult= "Cancel"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        Events = @{
            KeyDown = {
                # Bestätigt die Eingabe, wenn die Enter-Taste gedrückt wird, aber nur wenn der Fokus auf dem Input-Textfeld liegt
                if ($this.ActiveControl.Name -eq "Input") {
                    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                        $this.Controls["GroupBox"].Controls["InputTable"].Controls["Buttons"].Controls["OkButton"].PerformClick()
                    }
                }
            }
        }
    }

    $form = New-Form $FormConfig
    $result = $form.ShowDialog()
    $textBox = Get-Control $form "Input"

    if ($result -eq "OK") { return $textBox.Text } 
    elseif ($result -eq "Cancel") { return $false }
    else { return $null }
}