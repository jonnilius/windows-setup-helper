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