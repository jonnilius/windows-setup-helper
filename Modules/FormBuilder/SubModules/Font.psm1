using namespace System.Drawing
using namespace System.Windows.Forms

function Get-Font {
    param(
        [string]$Control,
        [int]$Size, 
        [string]$Name,
        [string[]]$Style,
        [string]$Preset
    )

    # Vordefinierte Schriftarteinstellungen basierend auf Control-Typ oder Preset auswählen
    if ($Control) {
        $fontPreset = @{
            Button          = @{ Size = 10; Name = "Consolas";  Style = "Regular" }
            CheckBox        = @{ Size = 9;  Name = "Consolas";  Style = "Regular" }
            CheckedListBox  = @{ Size = 9;  Name = "Consolas";  Style = "Regular" }
            ComboBox        = @{ Size = 10; Name = "Consolas";  Style = "Regular" }
            GroupBox        = @{ Size = 10; Name = "Consolas";  Style = "Regular" }
            Label           = @{ Size = 10; Name = "Tahoma";    Style = "Regular" }
            ListBox         = @{ Size = 10; Name = "Consolas";  Style = "Regular" }
            ListView        = @{ Size = 10; Name = "Consolas";  Style = "Regular" }
            RichTextBox     = @{ Size = 10; Name = "Consolas";  Style = "Regular" }
            TabControl      = @{ Size = 10; Name = "Consolas";  Style = "Regular" }
            TabPage         = @{ Size = 10; Name = "Consolas";  Style = "Regular" }
            TextBox         = @{ Size = 12; Name = "Segoe UI";  Style = "Bold" }
        }[$Control]
    } elseif ($Preset) {
        $fontPreset = @{
            # Hybrid Controls
            LabelButton     = @{ Size = 8;  Name = "Consolas";      Style = "Regular" }
            LabelItalic     = @{ Size = 10; Name = "Tahoma";        Style = "Italic" }
            
            # TabControl Presets
            TabLabel        = @{ Size = 10; Name = "Consolas";  Style = "Italic" }

            # Table Presets
            TableTitle      = @{ Size = 14; Name = "Tahoma"; Style = "Bold" }
            TableLabel      = @{ Size = 10; Name = "Tahoma"; Style = "Bold" }
            TableText       = @{ Size = 10; Name = "Tahoma"; Style = "Regular" }
            TableTextHover  = @{ Size = 10; Name = "Tahoma"; Style = "Italic" }
            TableLink       = @{ Size = 9;  Name = "Tahoma"; Style = "Italic" }
            TableButton     = @{ Size = 8;  Name = "Tahoma"; Style = "Bold" }

            # Sidebar Presets
            SidebarTitle            = @{ Size = 22; Name = "Cascadia Code"; Style = "Bold" }
            SidebarVersion          = @{ Size = 10; Name = "Consolas";      Style = "Regular" }
            SidebarButton           = @{ Size = 8;  Name = "Segoe UI";      Style = "Bold" }
            PackageInfoTitle        = @{ Size = 10; Name = "Tahoma";        Style = "Bold" }
            PackageInfoLabel        = @{ Size = 9;  Name = "Segoe UI";      Style = "Bold" }
            PackageInfoDescription  = @{ Size = 9;  Name = "Segoe UI";      Style = "Regular" }
            
            # Form Presets
            FooterLink      = @{ Size = 8;  Name = "Tahoma";    Style = "Bold" }
            FooterLinkHover = @{ Size = 8;  Name = "Tahoma";    Style = @("Bold", "Underline") }
            FooterText      = @{ Size = 9;  Name = "Consolas";  Style = "Italic" }

            # Other Presets
            SearchHeader    = @{ Size = 20; Name = "Cascadia Code"; Style = "Bold" }
            Title           = @{ Size = 18; Name = "Segoe UI";      Style = "Bold" }
            Subtitle        = @{ Size = 13; Name = "Segoe UI";      Style = @("Bold", "Underline") }
        }[$Preset]
    } else {
        $fontPreset = $null
    }
    if (-not $fontPreset) { $fontPreset = @{ Size = 10; Name = "Consolas"; Style = "Regular" } }

    # Bevorzugte Schriftarten definieren und die erste verfügbare auswählen
    $Size  = If ($Size) { $Size } else { $fontPreset.Size }
    $Name  = If ($Name) { $Name } else { $fontPreset.Name }
    $Style = If ($Style) { $Style } else { $fontPreset.Style }


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