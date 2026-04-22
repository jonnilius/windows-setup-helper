function Set-DeviceName { 
    $params = @{
        Title        = "PC umbenennen"
        Label        = "Neuer PC-Name:"
        DefaultValue = $env:COMPUTERNAME
        Icon         = "DeviceName"
        OKButtonText = "Umbenennen"
    }
    while ($true) {
        $result = Show-TextInput @params
        if ($result -eq $false) { break }
        if ($result -is [string] -and $result.Trim() -ne "") { 
            Rename-Computer -NewName $result -Force -WhatIf
            break
        }
    }
}