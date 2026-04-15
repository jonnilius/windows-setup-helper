using namespace System.Drawing

function Get-Icon {
    param ( [string]$Name = "Default", [string]$ScriptRoot = $PSScriptRoot )

    $iconPaths = ( $ScriptRoot, "$ScriptRoot/Assets", "$ScriptRoot/Icons", "$ScriptRoot/Assets/Icons" ) | Where-Object { Test-Path $_ }

    # Zuerst versuchen, das Icon in den möglichen Verzeichnissen zu finden, bevor der Standardpfad verwendet wird
    foreach ($path in $iconPaths) {
        foreach ($filename in @("$Name.ico", "Icon.ico")) {
            $iconPath = Join-Path $path $filename
            if (Test-Path $iconPath) { return [Icon]::new($iconPath) }
        }
    }

    # Fallback: Standard-Icon zurückgeben, wenn kein benutzerdefiniertes Icon gefunden wird
    return [Icon]::Application
}