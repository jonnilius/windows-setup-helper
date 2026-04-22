function Show-TextInput {
    param( 
        [string]$Title              = "Eingabe", 
        [string]$Label              = "Bitte geben Sie einen Wert ein:", 
        [string]$DefaultValue       = "", 
        [string]$Icon               = "TextInput",
        [string]$OKButtonText       = "OK",
        [string]$CancelButtonText   = "Abbrechen",
        [string]$WarningMessage     = $null
    )

    $FormConfig = @{
        Properties = @{
            Text            = "$Title -only"
            ClientSize      = if ($WarningMessage) { 300,140 } else { 300,110 }
            MinimizeBox     = $false
            KeyPreview      = $true
            FormBorderStyle = "FixedDialog"
            BackColor       = Get-Color "Dark"
            Icon            = $Icon
        }
        Controls = [ordered]@{
            GroupBox = @{
                Control     = "GroupBox"
                Text        = $Label
                Controls    = [ordered]@{
                    InputTable = @{
                        Control     = "TableLayoutPanel"
                        Row         = if ($WarningMessage) { @("100", "100", 34) } else { @("100", 34) }
                        Controls    = [ordered]@{
                            Input = @{
                                Control     = "TextBox"
                                Name        = "Input"
                                Text        = $DefaultValue
                                Margin     = [Padding]::new(5)
                                TextAlign   = "Center"
                            }
                            WarnLabel = @{
                                Control     = "Label"
                                Name        = "WarnLabel"
                                Text        = $WarningMessage
                                ForeColor   = Get-Color "Accent"
                                TextAlign   = "MiddleCenter"
                                Font        = Get-Font -Control "Label" -Style "Italic"
                                Visible     = if ($WarningMessage) { $true } else { $false }
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

    if ($WarningMessage) { [System.Media.SystemSounds]::Exclamation.Play() }
    $form = New-Form $FormConfig
    $result = $form.ShowDialog()
    $textBox = Get-Control $form "Input"

    if ($result -eq "OK") { return $textBox.Text } 
    elseif ($result -eq "Cancel") { return $false }
    else { return $null }
}