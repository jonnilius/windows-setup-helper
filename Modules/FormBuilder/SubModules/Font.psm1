using namespace System.Drawing
using namespace System.Windows.Forms
$FontKeys = @("Size", "Name", "Style")
$DefaultFont = @{ Size = 10; Name = "Consolas"; Style = "Regular" }
function Get-ControlFont {
    param( [string]$Control )
    
    $font = @{
            Button          = @{}
            CheckBox        = @{ Size = 9; }
            CheckedListBox  = @{ Size = 9; }
            ComboBox        = @{}
            GroupBox        = @{}
            Label           = @{ Name = "Tahoma" }
            ListBox         = @{}
            ListView        = @{}
            RichTextBox     = @{}
            TabControl      = @{}
            TabPage         = @{}
            TextBox         = @{ Size = 12; Name = "Segoe UI";  Style = "Bold" }
        }[$Control]
    foreach ($key in $FontKeys) { if (-not $font.ContainsKey($key)) { $font[$key] = $DefaultFont[$key] } }
    return $font
}
function Get-PresetFont {
    param( [string]$Preset )
    $font = @{
            # Label-Presets
            Header          = @{ Size = 25; Name = "Cascadia Code"; Style = "Bold" }
            LabelButton     = @{ Size = 8 }
            LabelItalic     = @{ Name = "Tahoma";    Style = "Italic" }

            # Tab-Presets
            TabLabel        = @{ Style = "Italic" }

            # Table-Presets
            TableTitle      = @{ Size = 14; Name = "Segoe UI";    Style = @("Bold", "Underline") }
            TableLabel      = @{ Name = "Tahoma";    Style = "Bold" }
            TableText       = @{ Name = "Tahoma" }
            TableTextHover  = @{ Name = "Tahoma";    Style = "Italic" }
            TableLink       = @{ Size = 9;  Name = "Tahoma";    Style = "Italic" }
            TableButton     = @{ Size = 8;  Name = "Tahoma";    Style = "Bold" }
            
            # Sidebar Presets
            SidebarTitle            = @{ Size = 22; Name = "Cascadia Code"; Style = "Bold" }
            SidebarVersion          = @{}
            SidebarButton           = @{ Size = 8;  Name = "Segoe UI";      Style = "Bold" }
            PackageInfoTitle        = @{ Name = "Tahoma";        Style = "Bold" }
            PackageInfoLabel        = @{ Size = 9;  Name = "Segoe UI";      Style = "Bold" }
            PackageInfoDescription  = @{ Size = 9;  Name = "Segoe UI" }
            # Form Presets
            FooterLink      = @{ Size = 8;  Name = "Tahoma";    Style = "Bold" }
            FooterLinkHover = @{ Size = 8;  Name = "Tahoma";    Style = @("Bold", "Underline") }
            FooterText      = @{ Size = 9;  Style = "Italic" }

            # Other Presets
            SearchHeader    = @{ Size = 20; Name = "Cascadia Code"; Style = "Bold" }
            Title           = @{ Size = 18; Name = "Segoe UI";      Style = "Bold" }
            Subtitle        = @{ Size = 13; Name = "Segoe UI";      Style = @("Bold", "Underline") }
        }[$Preset]
    foreach ($key in $FontKeys) { if (-not $font.ContainsKey($key)) { $font[$key] = $DefaultFont[$key] } }
    return $font
}

function Get-Font {
    param(
        [string]$Control,
        [int]$Size, 
        [string]$Name,
        [string[]]$Style,
        [string]$Preset
    )
    # Vordefinierte Schriftarteinstellungen basierend auf Control-Typ oder Preset auswählen
    $fontPreset = if ($Control) { Get-ControlFont -Control $Control } elseif ($Preset) { Get-PresetFont -Preset $Preset }

    # Bevorzugte Schriftarten definieren und die erste verfügbare auswählen
    $Size  = If ($Size)  { $Size }  elseif ($fontPreset.Size) { $fontPreset.Size } else { $DefaultPreset.Size }
    $Name  = If ($Name)  { $Name }  elseif ($fontPreset.Name) { $fontPreset.Name } else { $DefaultPreset.Name }
    $Style = If ($Style) { $Style } elseif ($fontPreset.Style) { $fontPreset.Style } else { $DefaultPreset.Style }


    # FontStyle-Enum aus einem oder mehreren übergebenen Styles aufbauen
    $fontEnum = [FontStyle]::Regular
    foreach ($singleStyle in @($Style | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
        switch ($singleStyle) {
            "Bold"      { $fontEnum = $fontEnum -bor [FontStyle]::Bold }
            "Italic"    { $fontEnum = $fontEnum -bor [FontStyle]::Italic }
            "Regular"   { $fontEnum = $fontEnum -bor [FontStyle]::Regular }
            "Strikeout" { $fontEnum = $fontEnum -bor [FontStyle]::Strikeout }
            "Underline" { $fontEnum = $fontEnum -bor [FontStyle]::Underline }
            default       { }
        }
    }

    # Liste der installierten Schriftarten abrufen
    $installedFonts     = [Text.InstalledFontCollection]::new().Families.Name
    $preferredFonts     = @($Name, "Segoe UI", "Tahoma", "Arial", "Microsoft Sans Serif")
    # Die erste verfügbare Schriftart aus der Liste der bevorzugten Schriftarten auswählen
    $resolvedFontName   = $preferredFonts | Where-Object { $_ -and ($installedFonts -contains $_) } | Select-Object -First 1
    if (-not $resolvedFontName) { $resolvedFontName = "Microsoft Sans Serif" }

    # Font-Objekt erstellen und zurückgeben    
    try {   return [Font]::new($resolvedFontName, $Size, $fontEnum) }
    catch { return [Font]::new("Microsoft Sans Serif", 10, [FontStyle]::Regular) }
}