function Show-CopyValueHover {
    param ( [Parameter(Mandatory=$true)][System.Windows.Forms.Label]$Label )

    # Speichere den ursprünglichen Text im Tag-Property, damit wir ihn später wiederherstellen können
    $Label.Tag = $Label.Text

    # Cursor auf Hand ändern, um anzuzeigen, dass es klickbar ist
    $Label.Cursor = Get-Cursor "Hand"

    # Füge MouseEnter- und MouseLeave-Events hinzu, um den Text und die Schriftart zu ändern
    $Label.Add_MouseEnter({ $this.Text = "Klicken zum Kopieren";    $this.Font = Get-Font -Preset "TableTextHover" })
    $Label.Add_MouseLeave({ $this.Text = $this.Tag;                 $this.Font = Get-Font -Preset "TableText" })

    # Füge ein Click-Event hinzu, um den Text in die Zwischenablage zu kopieren
    $Label.Add_Click({
        Set-Clipboard -Value $this.Tag
        Show-MessageBox -Text "'$($this.Tag)' wurde in die Zwischenablage kopiert." -Title "Kopiert" -Buttons "OK" -Icon "Information"
    })
}

function Set-DeviceName { 
    $params = @{
        Title        = "PC umbenennen"
        Label        = "Neuer PC-Name:"
        DefaultValue = $env:COMPUTERNAME
        Icon         = "DeviceName"
        OKButtonText = "Umbenennen"
        WarningMessage = $null
    }
    while ($true) {
        $result = Show-TextInput @params
        if ($result -eq $false) { break }

        $result = $result.Trim()
        if ($result -eq "") { $params.WarningMessage = "Der PC-Name darf nicht leer sein."; continue }
        elseif ($result -eq $params.DefaultValue) { $params.WarningMessage = "Die Namen müssen sich unterscheiden."; continue }
        elseif ($result -match '[\\\/:\*\?"<>\|]') { $params.WarningMessage = "Der PC-Name darf keine der folgenden Zeichen enthalten: \ / : * ? < > |"; continue }
        else {
            try {
                Rename-Computer -NewName $result -Force -ErrorAction Stop
                $params.WarningMessage = $null
                $confirmRestart = Show-MessageBox -Text "Der PC-Name wurde erfolgreich geändert. `nMöchten Sie jetzt neu starten, damit die Änderung wirksam wird?" -Title "Neustart erforderlich" -Buttons "YesNo" -Icon "Information"
                if ($confirmRestart) { Restart-Computer -Force }
                break
            } catch {
                $params.WarningMessage = "Ungültige Eingabe."
            }
        }
    }
}