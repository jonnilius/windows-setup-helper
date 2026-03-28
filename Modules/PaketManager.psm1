
function Get-ChocolateyList {
    try {
        # $apkList = New-Object System.Collections.ArrayList
        $chocoList = choco list  | Select-Object -Skip 1 | Select-Object -SkipLast 1
        $apkList = foreach ($apk in $chocoList) {
            $name, $version = $apk -split '\s+(?=\S+$)' 
            [PSCustomObject]@{
                Name    = $name
                Version = $version
            }
        }
        # Write-Host $apkList | Format-Table -AutoSize
        return $apkList | Sort-Object Name

    } catch { 
        # Wenn ein Fehler auftritt (z.B. Befehl nicht gefunden), wird eine leere Liste zurückgegeben
        return @( "Fehler mit Get-ChocolateyList" )
    }
}
function Get-ChocolateyVersion {
    try { 
        # Versucht, die Version von Chocolatey abzurufen
        return (choco --version).Trim() 
    } catch { 
        # Wenn ein Fehler auftritt (z.B. Befehl nicht gefunden), wird "Nicht installiert" zurückgegeben
        return "Nicht installiert"
    }
}

function Get-Chocolatey {
    param ( 
        [switch]$List, 
        [switch]$Version 
    )

    if ($List) { return Get-ChocolateyList
    } elseif ($Version) { return Get-ChocolateyVersion
    } else {
        # Prüfen, ob der Befehl "choco" verfügbar ist, ohne eine Fehlermeldung auszugeben
        $CommandSource = (Get-Command choco -ErrorAction SilentlyContinue).Source
        $NullOrWhitespace = [string]::IsNullOrWhiteSpace($CommandSource)
        return -not $NullOrWhitespace
    }
}

Export-ModuleMember -Function Get-Chocolatey