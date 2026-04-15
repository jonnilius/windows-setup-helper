using namespace System.Drawing

function Get-Color {
    param( [string]$Name )

    $Color = switch ($Name) {
        "Accent"        { "#C0393B" }
        "Dark"          { "#2D3436" }
        "White"         { "#EEEEEE" }
        "Debug1"        { "#27AE60" }
        "Debug2"        { "#2980B9" }
        "Debug3"        { "#8E44AD" }
        "Transparent"   { "#00000000" }
        default         { "#000" }
    }

    # Return
    return [ColorTranslator]::FromHtml($Color)
}