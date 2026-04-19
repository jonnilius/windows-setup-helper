$FormConfig = @{
    Properties = @{
        Text = "Neuer Gerätename"
        ClientSize  = [Size]::new(370,50)
        Padding     = [Padding]::new(5)
        FormBorderStyle = "FixedDialog"
        Icon = "Default"
    }
    Controls = @{
        TableLayout = @{
            Control = "TableLayoutPanel"
            Column  = @( "100", "AutoSize" )
            Row     = @( 36 )
            
            Padding = [Padding]::new(0)
            Controls = @{
                TextBox = @{
                    Control = "TextBox"
                    Position = 0,0
                    Dock = "Fill"
                    Margin = [Padding]::new(0,4,8,4)
                    Font = [Font]::new("Consolas", 20)
                    TextAlign = "Center"
                    BorderStyle = "None"
                    Text = $env:COMPUTERNAME
                    Multiline = $false
                }
                Button = @{
                    Control = "Button"
                    Position = 1,0
                    Dock = "None"
                    Anchor = "Left"
                    AutoSize = $true
                    MinimumSize = [Size]::new(80,28)
                    Margin = [Padding]::new(0,4,4,4)
                    Text = "Ändern"
                    FlatStyle = "Flat"
                    TextAlign = "MiddleCenter"
                    Add_Click = { Set-DeviceName -NewName (Get-Control $this "TextBox").Text }
                }
            }
        }
    }
    Events = @{
        Shown = { (Get-Control $this "TextBox").Focus() }
    }
}

function Set-DeviceName {
    param ( [string]$NewName )
    if ($NewName -eq $null -or $NewName.Trim() -eq "") {
        Show-MessageBox -Message "Der Gerätename wurde nicht geändert!" -Title "Fehler" -Buttons "OK" -Icon "Error"
    }
    else {
        Rename-Computer -NewName $NewName -Force
        $restart = Show-MessageBox -Message "Der Gerätename wurde erfolgreich geändert! `nStarten Sie den Computer neu, um die Änderungen zu übernehmen.`nMöchten Sie den Computer jetzt neu starten?" -Title "Erfolg" -Buttons "YesNo" -Icon "Question"
        if ($restart) {
            Restart-Computer -Force
        } else {
            Show-MessageBox -Message "Der Computer muss neu gestartet werden, damit die Änderung wirksam wird!" -Title "Neustart erforderlich" -Buttons "OK" -Icon "Warning"
        }
    }
}
function Start-DeviceNameUI { Start-Form $FormConfig }