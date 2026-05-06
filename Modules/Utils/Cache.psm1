# Cache.psm1 - Einfache globale Cache-Implementierung für PowerShell-Skripte
if (-not $script:Cache) { $script:Cache = @{} }

function Show-GlobalCache {
    param( [int]$KeySize = 15, $Prefix = "" )

    if (-not $script:Cache -or $script:Cache.Count -eq 0) { Write-Host "Cache ist leer." -ForegroundColor Yellow; return }
    
    Write-Host "Aktueller Cache-Inhalt:" -ForegroundColor Cyan
    foreach ($item in $script:Cache.GetEnumerator()){ 
        if ($item.Key -like "$Prefix*") {
            Write-Host $($item.Key).PadRight($KeySize) -NoNewline
            Write-Host ": $($item.Value)"
        }
    }
}
function Set-GlobalCache {
    param ( [string]$Key, $Value )
    if (-not $script:Cache) { $script:Cache = @{} }

    $script:Cache[$Key] = $Value
}
function Get-GlobalCache {
    param ( [string]$Key )

    if ($script:Cache.ContainsKey($Key)) { 
        return $script:Cache[$Key] 
    }

    return $null
}
function Test-GlobalCache {
    param ( [string]$Key, $Value )
    if (-not $script:Cache.ContainsKey($Key)) { $script:Cache[$Key] = $Value }
}