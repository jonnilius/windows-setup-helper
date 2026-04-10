using namespace System.Windows.Forms
using namespace System.Drawing
<### Georgia11 ##########################################################################
*                                                                                       *
*                 `7MM"""YMM                                                            *
*                   MM    `7                                                            *
*                   MM   d  ,pW"Wq.`7Mb,od8 `7MMpMMMb.pMMMb.  ,pP"Ybd                   *
*                   MM""MM 6W'   `Wb MM' "'   MM    MM    MM  8I   `"                   *
*                   MM   Y 8M     M8 MM       MM    MM    MM  `YMMMa.                   *
*                   MM     YA.   ,A9 MM       MM    MM    MM  L.   I8                   *
*                 .JMML.    `Ybmd9'.JMML.   .JMML  JMML  JMML.M9mmmP'                   *
*                                                                                       *
########################################################################################>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Write-Debug "[INIT] Importiere FormBuilder-Modul: $($MyInvocation.MyCommand.Name) | Version: $($MyInvocation.MyCommand.Version) | Pfad: $($MyInvocation.MyCommand.Path)"

function Get-Color {
    param( [string]$ColorName, 
    [switch]$Hex,
    [switch]$ColorObject
    )

    $color = switch ($ColorName) {
        "Accent" { "#C0393B" }
        "Dark"   { "#2D3436" }
        "White"  { "#EEEEEE" }
        "Debug1" { "#27AE60" }
        "Debug2" { "#2980B9" }
        "Debug3" { "#8E44AD" }
        "TestFG" { "#F39C12" }
        "Transparent" { "#00000000" }
        default  { "#000" }
    }

    if ($Hex) { return $color } 
    elseif ($ColorObject) { return [ColorTranslator]::FromHtml($color) } 
    else { return [ColorTranslator]::FromHtml($color) }
}
function Get-Font {
    param(
        [string]$Control,
        [int]$Size, 
        [string]$Name,
        [string[]]$Style
    )

    # Vordefinierte Schriftart-Einstellungen für verschiedene Steuerelemente
    $fontPreset = @{
        # Controls
        Button          = @{ Size = 10; Name = "Consolas";      Style = "Regular" }
        CheckedListBox  = @{ Size = 9;  Name = "Consolas";      Style = "Regular" }
        Label           = @{ Size = 10; Name = "Tahoma";        Style = "Regular" }
        ListBox         = @{ Size = 10; Name = "Consolas";      Style = "Regular" }
        TabControl      = @{ Size = 10; Name = "Consolas";      Style = "Regular" }
        TextBox         = @{ Size = 11; Name = "Segoe UI";      Style = "Bold" }

        # Hybrid Controls
        LabelButton     = @{ Size = 8;  Name = "Consolas";      Style = "Regular" }
        LabelItalic     = @{ Size = 10; Name = "Tahoma";        Style = "Italic" }
        
        # TabControl Presets
        TabLabel        = @{ Size = 10; Name = "Consolas";  Style = "Italic" }

        # Table Presets
        TableTitle      = @{ Size = 15; Name = "Cascadia Code"; Style = @("Bold", "Underline") }
        TableLabel      = @{ Size = 10; Name = "Cascadia Code"; Style = "Bold" }
        TableText       = @{ Size = 10; Name = "Cascadia Code"; Style = "Regular" }
        TableLink       = @{ Size = 9;  Name = "Cascadia Code"; Style = "Italic" }
        TableButton     = @{ Size = 8;  Name = "Cascadia Code"; Style = "Bold" }

        # Sidebar Presets
        SidebarTitle            = @{ Size = 22; Name = "Cascadia Code"; Style = "Bold" }
        SidebarVersion          = @{ Size = 10; Name = "Consolas";      Style = "Regular" }
        SidebarButton           = @{ Size = 8;  Name = "Segoe UI";      Style = "Bold" }
        PackageInfoTitle        = @{ Size = 10; Name = "Tahoma";        Style = "Bold" }
        PackageInfoLabel        = @{ Size = 9;  Name = "Segoe UI";      Style = "Bold" }
        PackageInfoDescription  = @{ Size = 9;  Name = "Segoe UI";      Style = "Regular" }
        
        # Other Presets
        SearchHeader    = @{ Size = 20; Name = "Cascadia Code"; Style = "Bold" }
        Title           = @{ Size = 18; Name = "Segoe UI";      Style = "Bold" }
        Subtitle        = @{ Size = 13; Name = "Segoe UI";      Style = @("Bold", "Underline") }
    }[$Control]
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
            "Regular"   { }
            "Strikeout" { $fontEnum = $fontEnum -bor [FontStyle]::Strikeout }
            "Underline" { $fontEnum = $fontEnum -bor [FontStyle]::Underline }
            default       { }
        }
    }

    # Alle installierten Schriftarten abrufen
    $installedFonts = [System.Drawing.Text.InstalledFontCollection]::new().Families.Name

    # Bevorzugte Schriftarten in der gewünschten Reihenfolge definieren
    $preferredFonts = @($Name, "Segoe UI", "Tahoma", "Arial", "Microsoft Sans Serif")

    # Die erste verfügbare Schriftart aus der Liste der bevorzugten Schriftarten auswählen
    $resolvedFontName = $preferredFonts | Where-Object { $_ -and ($installedFonts -contains $_) } | Select-Object -First 1

    # Wenn keine der bevorzugten Schriftarten gefunden wird, auf eine Standardschriftart zurückgreifen
    if (-not $resolvedFontName) {
        $resolvedFontName = "Microsoft Sans Serif"
    }
    
    try {
        return New-Object System.Drawing.Font($resolvedFontName, $Size, $fontEnum)
    }
    catch {
        return New-Object System.Drawing.Font("Microsoft Sans Serif", 10, [FontStyle]::Regular)
    }
}
function Get-Icon {
    param ( [string]$Name = "Default" )

    # Versuche, das angegebene Icon zu laden
    $iconPath = Join-Path $AppConfig.IconPath "$Name.ico"
    if (-not (Test-Path $iconPath)) { 
        Write-Warning "[WARN] Icon '$Name' nicht gefunden unter: $iconPath"
        $Name = "Default"
    }

    # Wenn das Standard-Icon nicht gefunden wird, gebe ein leeres Icon zurück
    $iconPath = Join-Path $AppConfig.IconPath "$Name.ico"
    if (-not (Test-Path $iconPath)) {
        Write-Error "[ERROR] Standard-Icon 'Default' nicht gefunden unter: $iconPath. Es wird kein Icon gesetzt."
        return [Icon]::Application
    }

    # Icon laden und zurückgeben
    return [Icon]::new($iconPath)
}
function Merge-Config {
    param( [hashtable[]]$Configs )
    # param( [hashtable]$DefaultConfig, [hashtable]$CustomConfig )

    $merged = @{}

    foreach ($hash in $Configs) {
    # foreach ($hash in @($DefaultConfig, $CustomConfig)) {
        if (-not $hash) { continue }

        foreach ($key in $hash.Keys) {
            $merged[$key] = $hash[$key]
        }
    }

    return $merged
}

<##############################################################################################>
$global:ToolTip = & {
    <#
    .SYNOPSIS
    Globales ToolTip-Objekt für Windows Forms Controls.

    .DESCRIPTION
    Da ToolTips in Windows Forms nicht direkt an die Controls gebunden werden können, 
    sondern über die SetToolTip-Methode des ToolTip-Objekts, wird ein globales ToolTip-Objekt 
    in der gesamten Anwendung verwendet. Dadurch können konsistente ToolTips mit einheitlichem 
    Styling und Verhalten bereitgestellt werden, ohne für jedes Control ein eigenes 
    ToolTip-Objekt erstellen zu müssen.

    .NOTES
    Das ToolTip-Objekt ist als globale Variable verfügbar und sollte für alle Controls 
    in der Anwendung verwendet werden, um ein konsistentes Erscheinungsbild zu gewährleisten.

    .EXAMPLE
    $ToolTip.SetToolTip($controlName, "Dies ist ein Tooltip-Text")

    .PROPERTY BackColor
    Setzt die Hintergrundfarbe des ToolTips auf eine dunkle Farbe für guten Kontrast zum Text.

    .PROPERTY ForeColor
    Setzt die Textfarbe des ToolTips auf Weiß für gute Lesbarkeit.

    .PROPERTY AutoPopDelay
    Gibt die Zeit in Millisekunden an, die das ToolTip angezeigt wird, 
    bevor es automatisch ausgeblendet wird.

    .PROPERTY InitialDelay
    Gibt die Zeit in Millisekunden an, die gewartet wird, bevor das ToolTip angezeigt wird, 
    nachdem der Benutzer den Mauszeiger über ein Steuerelement bewegt hat.

    .PROPERTY ReshowDelay
    Gibt die Zeit in Millisekunden an, die gewartet wird, bevor ein ToolTip erneut angezeigt wird, 
    nachdem es ausgeblendet wurde.
    #>
    $toolTip = New-Object System.Windows.Forms.ToolTip
    $toolTip.BackColor = Get-Color "Dark"
    $toolTip.ForeColor = Get-Color "White"
    $toolTip.AutoPopDelay = 5000
    $toolTip.InitialDelay = 500
    $toolTip.ReshowDelay = 500
    return $toolTip
}

<### LAYOUT-CONTAINER ###>
function New-Panel {
    param( [hashtable]$Config = @{} )
    $panel   = [Panel]::new()
    
    # Config mit Standardwerten mergen
    $Default = @{
        Dock = "Fill"
        ForeColor = Get-Color "Accent"
        BackColor = Get-Color "Dark"
    }
    $DefaultConfig = Merge-Config $Default, $Config

    # Properties und Events dynamisch setzen
    $type   = $panel.GetType()
    $events = $type.GetEvents().Name
    $prop   = $type.GetProperties().Name

    foreach ($key in $DefaultConfig.Keys) {
        if ($key -eq "Controls") { 
            $ControlConfig = $DefaultConfig[$key]
            foreach ($cfg in $ControlConfig.GetEnumerator()) {
                $control        = New-Control $cfg.Value
                $control.Name   = $cfg.Key
                $panel.Controls.Add($control)
            }
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $panel.$key($DefaultConfig[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $panel.$key($DefaultConfig[$key]) }
        } elseif ($prop -contains $key) { 
            $panel.$key = $DefaultConfig[$key] 
        } else {
            if ($panel.PSObject.Properties[$key]) {
                $panel.$key = $DefaultConfig[$key]
            }
        }
    }
    
    # Return
    return $panel
}
function New-FlowLayoutPanel {
    param( [hashtable]$Config = @{} )
    $flowPanel = [FlowLayoutPanel]::new()

    # Config mit Standardwerten mergen
    $prep = Merge-Config @{
        Dock             = "Fill"
        AutoScroll       = $false
        WrapContents     = $false
        FlowDirection    = "TopDown"
        ForeColor        = Get-Color "Accent"
        BackColor        = Get-Color "Dark"
    }, $Config

    # Properties und Events dynamisch setzen
    $type   = $flowPanel.GetType()
    $props  = $type.GetProperties().Name
    $events = $type.GetEvents().Name

    foreach ($key in $prep.Keys) {
        if ($key -eq "Controls") { 
            $ControlConfig = $prep[$key]
            foreach ($cfg in $ControlConfig.GetEnumerator()) {
                $control        = New-Control $cfg.Value
                $control.Name   = $cfg.Key
                $flowPanel.Controls.Add($control)
            }
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $flowPanel.$key($prep[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $flowPanel.$key($prep[$key]) }
        } elseif ($props -contains $key) { 
            $flowPanel.$key = $prep[$key] 
        } else {
            if ($flowPanel.PSObject.Properties[$key]) {
                $flowPanel.$key = $prep[$key]
            }
        }
    }

    # Return
    return $flowPanel
}
function New-TableLayoutPanel {
    param ( $Config = @{} )
    $table = [TableLayoutPanel]::new()
    $default = @{
        Dock = "Fill"
        ForeColor = Get-Color "Accent"
        BackColor = Get-Color "Dark"
    }
    
    # Config mit Standardwerten mergen
    $defaultConfig = Merge-Config $default, $Config

    # Properties und Events dynamisch setzen
    $type   = $table.GetType()
    $events = $type.GetEvents().Name
    $props  = $type.GetProperties().Name

    foreach ($key in $defaultConfig.Keys) {
        if ($key -eq "Controls") { 
            foreach ($cfg in $defaultConfig[$key].GetEnumerator()) {
                $controlConfig  = $cfg.Value
                $control        = New-Control $controlConfig
                $control.Name   = $cfg.Key

                # Nur automatisch auf Fill docken, wenn kein explizites Layout im Control gesetzt ist.
                $hasExplicitDock = $controlConfig.ContainsKey("Dock")
                $hasExplicitAnchor = $controlConfig.ContainsKey("Anchor")
                $disableAutoCellDock = $controlConfig.ContainsKey("AutoCellDock") -and -not [bool]$controlConfig["AutoCellDock"]
                if (-not $hasExplicitDock -and -not $hasExplicitAnchor -and -not $disableAutoCellDock) {
                    $control.Dock = "Fill"
                }

                if ($controlConfig.Position) {
                    $pos = $controlConfig.Position
                    
                    # Column
                    $col = if($null -ne $pos.Column) { $pos.Column } else { $pos[0] }
                    if ($col -is [array]){ $colPos = $col[0]; $colSpan = $col[1] - $col[0] + 1 } 
                    else { $colPos = $col; $colSpan = 1 }

                    # Row
                    $row = if($null -ne $pos.Row) {    $pos.Row }    else { $pos[1] }
                    if ($row -is [array]){ $rowPos = $row[0]; $rowSpan = $row[1] - $row[0] + 1 }
                    else { $rowPos = $row; $rowSpan = 1 }
                    
                    # Control hinzufügen
                    $table.Controls.Add($control, $colPos, $rowPos)

                    # Span setzen, falls angegeben
                    if ($colSpan -gt 1) { $table.SetColumnSpan($control, $colSpan) }
                    if ($rowSpan -gt 1) { $table.SetRowSpan($control, $rowSpan) }

                } else { $table.Controls.Add($control) }
                if ($null -ne $controlConfig.ColumnSpan) { $table.SetColumnSpan($control, $controlConfig.ColumnSpan) }
                if ($null -ne $controlConfig.RowSpan)    { $table.SetRowSpan($control, $controlConfig.RowSpan) }
            }
            continue
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $table.$key($defaultConfig[$key]) }
            continue
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $table.$key($defaultConfig[$key]) }
            continue
        } elseif ($key -in @("Column", "Row")) {
            # Spezialbehandlung für RowStyles und ColumnStyles, da diese komplexe Objekte sind und nicht direkt über die Property gesetzt werden können
            $keyConfig  = $defaultConfig[$key]
            $isColumn   = $key -eq "Column"
            $sizeTypes  = "Percent", "AutoSize", "Absolute"

            # Alte Styles entfernen
            if ($isColumn) { $table.ColumnStyles.Clear() } else { $table.RowStyles.Clear() }

            # Anzahl der Spalten/Zeilen setzen
            if ($isColumn) { $table.ColumnCount = $keyConfig.Count } else { $table.RowCount = $keyConfig.Count }
            
            # Neue Styles hinzufügen
            foreach ($style in $keyConfig) { 

                # Wenn bereits ein gültiges TableLayoutStyle-Objekt übergeben wird, dieses direkt verwenden
                $keyStyle = if ($style -is [System.Windows.Forms.TableLayoutStyle]) { $style 

                # Andernfalls versuchen, die übergebenen Werte zu interpretieren und ein neues TableLayoutStyle-Objekt zu erstellen.
                } else {

                    # Startwerte für SizeType und Dimension festlegen
                    $sizeType   = "AutoSize"
                    $dimension  = 0

                    
                    # Wenn ein String übergeben wird, könnte es sich um einen Prozentwert oder einen SizeType handeln
                    if ($style -is [string]) { 

                        # Wenn der String nur aus Ziffern besteht und zwischen 0 und 100 liegt, interpretieren wir ihn als Prozentwert
                        if ($style -match '^\d+$' -and ([int]$style -ge 0 -and [int]$style -le 100)) {
                            $sizeType   = "Percent"
                            $dimension  = [int]$style

                        # Wenn der String einem der SizeTypes entspricht, verwenden wir diesen SizeType mit der Standarddimension von 0 (für AutoSize) oder 100 (für Percent)
                        } elseif ($sizeTypes -contains $style) { $sizeType = $style }

                    # Wenn ein Integer übergeben wird, interpretieren wir ihn als absoluten Wert in Pixeln
                    } elseif ($style -is [int]) {
                        $sizeType   = "Absolute"
                        $dimension  = $style

                    # Wenn ein Array übergeben wird, könnte es sich um eine Kombination aus SizeType und Dimension handeln, z.B. ["Percent", 50] oder ["Absolute", 100]
                    } elseif ($style -is [array]) {

                        # Wenn der erste Wert ein gültiger SizeType ist, verwenden wir diesen. Ansonsten bleibt der Standard-SizeType "AutoSize" erhalten.
                        if ($style[0] -in $sizeTypes) { $sizeType = $style[0] } 

                        # Wenn ein zweiter Wert vorhanden ist und eine gültige Dimension darstellt (z.B. eine positive Zahl), verwenden wir diesen als Dimension. Ansonsten bleibt die Standard-Dimension 0 (für AutoSize) oder 100 (für Percent) erhalten.
                        if ($style.Count -gt 1 -and $style[1] -ge 0) { $dimension = $style[1] } 
                    } 

                    # Neues ColumnStyle- oder RowStyle-Objekt basierend auf den ermittelten SizeType- und Dimension-Werten erstellen
                    if ($isColumn) { [ColumnStyle]::new([SizeType]::$sizeType, $dimension) }
                    else { [RowStyle]::new([SizeType]::$sizeType, $dimension) }
                }
                
                # Neuen Style zum TableLayoutPanel hinzufügen
                if ($isColumn) { [void]$table.ColumnStyles.Add($keyStyle) }
                else { [void]$table.RowStyles.Add($keyStyle) }
            }
            continue
        } elseif ($key -eq "Position") {
            continue # Position wird speziell bei Controls innerhalb eines TableLayoutPanels behandelt, daher hier übersprungen
        } elseif ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($table, $defaultConfig[$key])
            continue
        } elseif ($props -contains $key) { 
            $table.$key = $defaultConfig[$key] 
        } else {
            if ($table.PSObject.Properties[$key]) {
                $table.$key = $defaultConfig[$key]
            }
        }
    }    

    # Return
    $table
}


<### STRUKTUR-CONTAINER ###>
function New-GroupBox {
    param ( [hashtable]$Config = @{} )

    $groupBox = [GroupBox]::new()
    $groupBox.ForeColor = Get-Color "Accent"
    $groupBox.BackColor = Get-Color "Dark"
    $groupBox.Font = [Font]::new("Consolas", 10)

    # Properties und Events dynamisch setzen
    $events = $groupBox.GetType().GetEvents().Name
    $prop   = $groupBox.GetType().GetProperties().Name
    foreach ($key in $Config.Keys) {
        if ($key -eq "Controls") { 
            $ControlConfig = $Config[$key]
            foreach ($item in $ControlConfig.GetEnumerator()) {
                $control        = New-Control $item.Value
                $control.Name   = $item.Key
                $groupBox.Controls.Add($control)
            }
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $groupBox.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $groupBox.$key($Config[$key]) }
        } elseif ($prop -contains $key) { 
            $groupBox.$key = $Config[$key] 
        } else {
            if ($groupBox.PSObject.Properties[$key]) {
                $groupBox.$key = $Config[$key]
            }
        }
    }

    return $groupBox
}
function New-TabControl {
    param ( $Config = @{} )
    
    $tabControl     = [TabControl]::new()
    $defaultConfig  = @{
        Dock = "Fill"
        Font = Get-Font -Control "TabControl"
    }
    foreach ($key in $defaultConfig.Keys) { $tabControl.$key = $defaultConfig[$key] }

    # Properties und Events dynamisch setzen
    $type   = $tabControl.GetType()
    $prop   = $type.GetProperties().Name
    $events = $type.GetEvents().Name

    foreach ($key in $Config.Keys) {
        if ($key -eq "Controls"){
            $ControlConfig = $Config[$key]
            foreach ($item in $ControlConfig.GetEnumerator()) {
                $control        = New-Control $item.Value
                $control.Name   = $item.Key
                $tabControl.TabPages.Add($control)
            }
            continue
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $tabControl.$key($Config[$key]) }
            continue
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $tabControl.$key($Config[$key]) }
            continue
        } elseif ($prop -contains $key) { 
            $tabControl.$key = $Config[$key] 
        } else {
            if ($tabControl.PSObject.Properties[$key]) {
                $tabControl.$key = $Config[$key]
            }
        }
    }    
    return $tabControl
}
function New-TabPage {
    param ( $Config = @{} )
    
    $tabPage = [TabPage]::new()
    $tabPage.BorderStyle    = "None"
    $tabPage.BackColor      = Get-Color "Dark"
    $tabPage.ForeColor      = Get-Color "Accent"
    $tabPage.Font           = Get-Font -Name "Tahoma" -Size 10

    # Properties und Events dynamisch setzen
    $prop   = $tabPage.GetType().GetProperties().Name
    $events = $tabPage.GetType().GetEvents().Name
    foreach ($key in $Config.Keys) {
        if ($key -eq "Controls") { 
            $ControlConfig = $Config[$key]
            foreach ($item in $ControlConfig.GetEnumerator()) {
                $control        = New-Control $item.Value
                $control.Name   = $item.Key
                $tabPage.Controls.Add($control)
            }
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $tabPage.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $tabPage.$key($Config[$key]) }
        } elseif ($prop -contains $key) { 
            $tabPage.$key = $Config[$key] 
        } else {
            if ($tabPage.PSObject.Properties[$key]) {
                $tabPage.$key = $Config[$key]
            }
        }
    }    
    
    $tabPage
}

<### HYBRID-CONTAINER ###>
function New-PanelTabControl {
    param ( $Config = @{} )
    $panel = [Panel]::new()

    # Config mit Standardwerten mergen
    $copy = Merge-Config @{
        Dock = "Fill"
    }, $Config

    <#
    Eigenschaften für Panel extrahieren:
    - Dock = TabControl füllt den gesamten Platz des Panels aus. Dock wird nur auf das Panel angewendet.
    - Margin = funktioniert weder bei TabControl noch bei Panel, daher wird das Margin auf das Panel angewendet.
    - Padding = funktioniert beim Panel, aber nicht beim TabControl, daher wird das Padding auf das Panel angewendet.
    #>
    $panelProps = @("Margin", "Padding", "Dock", "BackColor", "ForeColor")
    foreach ($prop in $panelProps) {
        if ($copy.ContainsKey($prop)) {
            $panel.$prop = $copy[$prop]
            [void]$copy.Remove($prop) # Entferne die Panel-spezifischen Properties aus der Config, damit sie nicht fälschlicherweise auf das TabControl angewendet werden
        }
    }

    # TabControl erstellen
    $tabControl = New-TabControl $copy
    $tabControl.Dock = "Fill" 

    $panel.Controls.Add($tabControl)

    return $panel
}




<### LEAF CONTROLS ###>
function New-Button {
    param( [hashtable]$Config = @{} )
    $button = [Button]::new()
    
    # Standardwerte für Buttons definieren, die bei Bedarf überschrieben werden können
    $default = @{
        Height = 30
        FlatStyle = "Flat"
        Cursor = Get-Cursor "Hand"
        Font = Get-Font -Control "Button"
        ForeColor = Get-Color "Accent"
        BackColor = Get-Color "Dark"
    }
    $Config = Merge-Config $default, $Config

    # Properties und Events dynamisch setzen
    $type   = $button.GetType()
    $events = $type.GetEvents().Name
    $prop   = $type.GetProperties().Name

    foreach ($key in $Config.Keys) {
        if ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($button, $Config[$key])
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $button.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $button.$key($Config[$key]) }
        } elseif ($prop -contains $key) { 
            $button.$key = $Config[$key]
        } else {
            if ($button.PSObject.Properties[$key]) {
                $button.$key = $Config[$key]
            }
        }
    }

    # Return
    return $button
}
function New-CheckBox {
    param ( [hashtable]$Config = @{} )

    $checkBox = [CheckBox]::new()

    $checkBox.AutoSize  = $false
    $checkBox.ForeColor = Get-Color "White"
    $checkBox.BackColor = Get-Color "Dark"
    $checkBox.Font      = [Font]::new("Consolas", 10)

    # Properties und Events dynamisch setzen
    $events = $checkBox.GetType().GetEvents().Name
    $prop   = $checkBox.GetType().GetProperties().Name
    foreach ($key in $Config.Keys) {
        if ($key -like "Add_*") {
            $name = $key.Substring(4)
            if ($events -contains $name) { $checkBox.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") {
            $name = $key.Substring(7)
            if ($events -contains $name) { $checkBox.$key($Config[$key]) }
        } elseif ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($checkBox, $Config[$key])
        } elseif ($prop -contains $key) {
            $checkBox.$key = $Config[$key]
        } else {
            if ($checkBox.PSObject.Properties[$key]) {
                $checkBox.$key = $Config[$key]
            }
        }
    }

    $checkBox
}
function New-CheckedListBox {
    param ( [hashtable]$Config = @{} )
    $Default = @{
        Font            = Get-Font -Control "CheckedListBox"
        BorderStyle     = "None"
        ForeColor       = Get-Color "White"
        BackColor       = Get-Color "Dark"
        DisplayMember   = "Name"
        CheckOnClick    = $true
    }
    
    # CheckedListBox erstellen und Standardwerte mergen
    $checkedListBox = [CheckedListBox]::new()
    $DefaultConfig  = Merge-Config $Default, $Config


    # Dynamisch Properties und Events setzen
    $type   = $checkedListBox.GetType()
    $events = $type.GetEvents().Name
    $prop   = $type.GetProperties().Name

    foreach ($key in $DefaultConfig.Keys) {
        if ($key -like "Add_*") { 
            $name = $key.Substring(4) # Eventnamen extrahieren, z.B. "SelectedIndexChanged" aus "Add_SelectedIndexChanged"
            if ($events -contains $name) { $checkedListBox.$key($DefaultConfig[$key]) }
            continue
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) # Eventnamen extrahieren, z.B. "SelectedIndexChanged" aus "Remove_SelectedIndexChanged"
            if ($events -contains $name) { $checkedListBox.$key($DefaultConfig[$key]) }
            continue
        } elseif ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($checkedListBox, $DefaultConfig[$key])
            continue
        } elseif ($key -eq "Items") {
            foreach ($program in $DefaultConfig[$key]) {
                $id     = if ($program.PSObject.Properties["Id"]) { $program.Id } elseif ($program.PSObject.Properties["Key"]) { $program.Key } else { $null }
                $name   = if ($program.PSObject.Properties["Name"]) { $program.Name } elseif ($program.PSObject.Properties["Value"]) { $program.Value } else { $id }
                $item   = [PSCustomObject]@{
                    Id      = $id
                    Name    = $name
                }
                [void]$checkedListBox.Items.Add($item, $false)
            }
            continue
        } elseif ($prop -contains $key) { 
            $checkedListBox.$key = $DefaultConfig[$key]
            continue
        } else {
            if ($checkedListBox.PSObject.Properties[$key]) { $checkedListBox.$key = $DefaultConfig[$key] }
        }
    }

    # Return
    return $checkedListBox
}
function New-ComboBox {
    param ( [hashtable]$Config = @{} )

    $comboBox = [ComboBox]::new()

    $comboBox.DropDownStyle = "DropDownList"
    $comboBox.Font          = [Font]::new("Consolas", 10)
    $comboBox.ForeColor     = Get-Color "White"
    $comboBox.BackColor     = Get-Color "Dark"

    # Properties und Events dynamisch setzen
    $events = $comboBox.GetType().GetEvents().Name
    $prop   = $comboBox.GetType().GetProperties().Name
    $deferredSelectedIndex = $null
    foreach ($key in $Config.Keys) {
        if ($key -like "Add_*") {
            $name = $key.Substring(4)
            if ($events -contains $name) { $comboBox.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") {
            $name = $key.Substring(7)
            if ($events -contains $name) { $comboBox.$key($Config[$key]) }
        } elseif ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($comboBox, $Config[$key])
        } elseif ($key -eq "Items") {
            foreach ($item in $Config[$key]) {
                $comboBox.Items.Add($item) | Out-Null
            }
        } elseif ($key -eq "SelectedIndex") {
            # Erst nach Items setzen, sonst ist 0 ungueltig, wenn Items noch leer sind.
            $deferredSelectedIndex = [int]$Config[$key]
        } elseif ($prop -contains $key) {
            $comboBox.$key = $Config[$key]
        } else {
            if ($comboBox.PSObject.Properties[$key]) {
                $comboBox.$key = $Config[$key]
            }
        }
    }

    if ($null -ne $deferredSelectedIndex -and $comboBox.Items.Count -gt 0) {
        if ($deferredSelectedIndex -ge 0 -and $deferredSelectedIndex -lt $comboBox.Items.Count) {
            $comboBox.SelectedIndex = $deferredSelectedIndex
        }
    }

    $comboBox
}
function New-Label {
    param( [hashtable]$Config = @{}  )
    $default = @{
        Font        = Get-Font -Control "Label"
        Text        = "New-Label Text"
        TextAlign   = "MiddleCenter"
    }
    
    # Label erstellen und Standardwerte mergen
    $label  = [Label]::new()
    $Config = Merge-Config $default, $Config
    
    # Properties und Events dynamisch setzen
    $type   = $label.GetType()
    $events = $type.GetEvents().Name
    $prop   = $type.GetProperties().Name

    foreach ($key in $Config.Keys) {
        if ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($label, $Config[$key])
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $label.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $label.$key($Config[$key]) }
        } elseif ($prop -contains $key) {
            $label.$key = $Config[$key]
        } else {
            if ($label.PSObject.Properties[$key]) {
                $label.$key = $Config[$key]
            }
        }
    }

    # Return
    return $label
}
function New-ListBox {
    param ( [hashtable]$Config = @{} )
    $Default = @{
        DisplayMember = "Name"
        SelectionMode = "MultiSimple"
        Font          = Get-Font -Control "ListBox"
        ForeColor     = Get-Color "White"
        BackColor     = Get-Color "Dark"
        BorderStyle   = "None"
        Dock          = "Fill"
    }
    $prep = Merge-Config $Default, $Config

    $listBox = [ListBox]::new()


    # Dynamisch Properties und Events setzen
    $type   = $listBox.GetType()
    $events = $type.GetEvents().Name
    $props  = $type.GetProperties().Name

    foreach ($key in $prep.Keys) {
        if ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($listBox, $prep[$key])
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $listBox.$key($prep[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $listBox.$key($prep[$key]) }
        } elseif ($key -eq "Items") {
            Write-Host "Erstelle eine ListBox"
            Write-Host $prep[$key].GetType().FullName
            foreach ($program in $prep[$key]) {
                $item = [PSCustomObject]@{
                    Id      = $program.Key
                    Name    = $program.Value
                }
                $listBox.Items.Add($item) | Out-Null
            }
        } elseif ($props -contains $key) {
            $listBox.$key = $prep[$key]
        } else {
            if ($listBox.PSObject.Properties[$key]) {
                $listBox.$key = $prep[$key]
            }
        }
    }

    $listBox
}
function New-NumericUpDown {
    param ( [hashtable]$Config = @{} )

    $numericUpDown = [NumericUpDown]::new()
    # $numericUpDown.Controls[0].Visible = $false # Pfeile ausblenden

    # Properties und Events dynamisch setzen
    $events = $numericUpDown.GetType().GetEvents().Name
    $prop   = $numericUpDown.GetType().GetProperties().Name
    foreach ($key in $Config.Keys) {
        if ($prop -contains $key) { 
            $numericUpDown.$key = $Config[$key] 
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $numericUpDown.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $numericUpDown.$key($Config[$key]) }
        } elseif ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($numericUpDown, $Config[$key])
        } else {
            if ($numericUpDown.PSObject.Properties[$key]) {
                $numericUpDown.$key = $Config[$key]
            }
        }
    }

    $numericUpDown
}
function New-ProgressBar {
param ( [hashtable]$Config = @{} )

    $progressBar = [ProgressBar]::new()

    $progressBar.Style     = "Continuous"
    $progressBar.Minimum   = 0
    $progressBar.Maximum   = 100
    $progressBar.Value     = 0
    $progressBar.ForeColor = Get-Color "Accent"
    $progressBar.BackColor = Get-Color "Dark"

    # Properties und Events dynamisch setzen
    $events = $progressBar.GetType().GetEvents().Name
    $prop   = $progressBar.GetType().GetProperties().Name
    foreach ($key in $Config.Keys) {
        if ($key -like "Add_*") {
            $name = $key.Substring(4)
            if ($events -contains $name) { $progressBar.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") {
            $name = $key.Substring(7)
            if ($events -contains $name) { $progressBar.$key($Config[$key]) }
        } elseif ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($progressBar, $Config[$key])
        } elseif ($prop -contains $key) {
            $progressBar.$key = $Config[$key]
        } else {
            if ($progressBar.PSObject.Properties[$key]) {
                $progressBar.$key = $Config[$key]
            }
        }
    }

    $progressBar
}
function New-RichTextBox {
    param ( [hashtable]$Config = @{} )

    $richTextBox = [RichTextBox]::new()
    
    $richTextBox.Font        = [Font]::new("Consolas", 10)
    $richTextBox.Text        = "kein Text angegeben"
    $richTextBox.ReadOnly    = $true
    $richTextBox.ForeColor   = Get-Color "White"
    $richTextBox.BackColor   = Get-Color "Dark"
    $richTextBox.BorderStyle = "None"

    # Properties und Events dynamisch setzen
    $prop    = $richTextBox.GetType().GetProperties().Name
    $events  = $richTextBox.GetType().GetEvents().Name
    foreach ($key in $Config.Keys) {
        if ($prop -contains $key) { 
            $richTextBox.$key = $Config[$key] 
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $richTextBox.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $richTextBox.$key($Config[$key]) }
        } elseif ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($richTextBox, $Config[$key])
        } else {
            if ($richTextBox.PSObject.Properties[$key]) {
                $richTextBox.$key = $Config[$key]
            }
        }
    }
    
    $richTextBox
}
function New-TextBox {
    param ( [hashtable]$Config = @{} )
    $default = @{
        Font        = Get-Font -Control "TextBox"
        BorderStyle = "None"
    }
    
    # TextBox erstellen und Standardwerte mergen
    $textbox = [TextBox]::new()
    $Config = Merge-Config $default, $Config

    # Properties und Events dynamisch setzen
    $type   = $textbox.GetType()
    $events = $type.GetEvents().Name
    $prop   = $type.GetProperties().Name

    foreach ($key in $Config.Keys) {
        if ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($textbox, $Config[$key])
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $textbox.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $textbox.$key($Config[$key]) }
        } elseif ($prop -contains $key) { 
            $textbox.$key = $Config[$key] 
        } else {
            if ($textbox.PSObject.Properties[$key]) { 
                $textbox.$key = $Config[$key] 
            }
        }
    }

    # Return
    return $textbox
}


<# FORM #>
function New-Form {
    param( [hashtable]$Config = @{} )
    # Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name) | Params: $($PSBoundParameters | Out-String)"

    # Form erstellen
    $form = [Form]::new()

    # Standard-Stil anwenden
    $form.StartPosition = "CenterScreen"
    $form.BackColor     = [ColorTranslator]::FromHtml("#C0393B")
    $form.ForeColor     = [ColorTranslator]::FromHtml("#2D3436") 
    $form.Padding       = [Padding]::new(10)
    $form.MaximizeBox   = $false
    $form.Text          = $AppInfo.Name
    $form.Icon          = Get-Icon "Default"

    # Properties dynamisch setzen
    if ($Config.ContainsKey("Properties")) {
        $props = $form.GetType().GetProperties().Name
        foreach ($key in $Config.Properties.Keys) {
            switch ($key) {
                # Spezialbehandlung für Text, um den Form-Namen voranzustellen (z.B. "Einstellungen – MeinApp")
                "Text" {
                    $formName = ($Config.Properties[$key])
                    $form.Text = "$formName – " + $form.Text
                    break
                }
                default {
                    # Versuche zuerst, die Property direkt zu setzen, wenn sie existiert
                    if ( $props -contains $key) { $form.$key = $Config.Properties[$key] } 
                    elseif ($form.PSObject.Properties.Match($key)) { $form.$key = $Config.Properties[$key] } 
                    else { Write-Warning "Unbekannte Form-Property: $key" }
                }
            }
        }
    }

    # Controls hinzufügen
    if ($Config.ContainsKey("Controls")) {
        foreach ($controlName in $Config.Controls.Keys) {
            
            # Konfiguration des Controls abrufen
            $ControlConfig = $Config.Controls[$controlName]

            # Kontrolle, ob der Control-Typ angegeben ist
            if (-not $ControlConfig.ContainsKey("Control")) { Write-Warning "Control '$controlName' fehlt die Angabe des Control-Typs. Control wird übersprungen."; continue } 

            # Control erstellen und hinzufügen
            $Control        = New-Control $ControlConfig
            $Control.Name   = $controlName
            $form.Controls.Add($Control)
        }
    }

    # Events hinzufügen
    if ($Config.ContainsKey("Events")) {
        $events = $form.GetType().GetEvents().Name
        foreach ($key in $Config.Events.Keys) {

            # Präfix "Add_" erkennen, um Event-Handler hinzuzufügen (z.B. "Add_Click" für das Click-Event)
            if ($key -like "Add_*") { 
                $name = $key.Substring(4)
                if ($events -contains $name) { $form.$key($Config.Events[$key]) }
                Write-Warning "Präfix 'Add_' erkannt. Stelle sicher, dass die Event-Handler korrekt benannt sind: $name"

            # Präfix "Remove_" erkennen, um Event-Handler zu entfernen (z.B. "Remove_Click" für das Click-Event)
            } elseif ($key -like "Remove_*") {
                $name = $key.Substring(7)
                if ($events -contains $name) { $form.$key($Config.Events[$key]) }
                Write-Warning "Präfix 'Remove_' erkannt. Stelle sicher, dass die Event-Handler korrekt benannt sind: $name"

            # Direkter Event-Name ohne Präfix (z.B. "Click") - in diesem Fall wird angenommen, dass es sich um einen Hinzufügen-Handler handelt
            } elseif ($events -contains $key) {
                $name = "Add_$key"
                $form.$name($Config.Events[$key])
            }
        }
    }

    # Alle Controls im Formular registrieren, damit sie über Get-Control mit ihrem Namen gefunden werden können
    $FormRefs = @{}
    Register-Control -control $form -refs $FormRefs
    $form.Tag = @{ Refs = $FormRefs }

    # Form zurückgeben
    return $form
}

function Resize-Form {
    param ( $Form, [int]$fontSize = 10 )

    # Berechne den Skalierungsfaktor basierend auf der ClientSize des Formulars
    $sx = $Form.ClientSize.Width / 400
    $sy = $Form.ClientSize.Height / 400
    $scale = [Math]::Min($sx, $sy)

    return $scale * $fontSize
}
function Start-Form {
    param ( $Config = @{}, $ShowDialog = $true )
    
    Set-Cursor "AppStarting"
    $form = New-Form $Config
    
    if ($ShowDialog) { 
        $form.ShowDialog() 
        $form.Dispose()
    } else { 
        $form.Show() 
    }

     # Warte, bis das Formular geschlossen wird, bevor die Funktion zurückkehrt
}

<# CONTROL #>
function New-Control {
    param( [hashtable]$Config )
    # Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name) | Params: $($PSBoundParameters | Out-String)"

    if (-not $Config.Control) { throw "Config fehlt das Feld 'Control'" }

    # Control-Typ ermitteln und Control erstellen
    $type = $Config.Control
    $copy = $Config.Clone()
    $copy.Remove("Control")
    
    switch ($type) {
        # Layout-Container
        "Panel" {            return New-Panel $copy }
        "FlowLayoutPanel" {  return New-FlowLayoutPanel $copy }
        "TableLayoutPanel" { return New-TableLayoutPanel $copy }

        # Struktur-Container
        "GroupBox" {   return New-GroupBox $copy }
        "TabControl" { return New-TabControl $copy }
        "TabPage" {    return New-TabPage $copy }

        # Hybrid-Container
        "PanelTabControl" { return New-PanelTabControl $copy }
        
        # Leaf Controls
        "Button" {         return New-Button $copy }
        "CheckBox" {       return New-CheckBox $copy }
        "CheckedListBox" { return New-CheckedListBox $copy }
        "ComboBox" {       return New-ComboBox $copy }
        "Label"  {         return New-Label $copy }
        "ListBox" {        return New-ListBox $copy }
        "NumericUpDown" {  return New-NumericUpDown $copy }
        "ProgressBar" {    return New-ProgressBar $copy }
        "RichTextBox" {    return New-RichTextBox $copy }
        "TextBox" {        return New-TextBox $copy }
        
        default { throw "Unbekannter Control-Typ: $type" }
    }
}
function Register-Control {
    param( $control, [hashtable]$refs )
    # Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name) | Params: $($PSBoundParameters | Out-String)"

    # Wenn der Control einen Namen hat, füge ihn zu den Referenzen hinzu
    if ($control.Name) { $Refs[$control.Name] = $control }

    # Rekursiv alle untergeordneten Controls registrieren
    foreach ($child in $control.Controls) { Register-Control -control $child -refs $Refs }
}
function Get-Control {
    param( $control, $name )
    # Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name) | Params: $($PSBoundParameters | Out-String)"

    # Formular des Controls finden, da die Referenzen auf Formularebene gespeichert werden
    $form = $control.FindForm()

    # Überprüfen, ob das Formular und die Referenzen vorhanden sind, bevor versucht wird, auf die Referenzen zuzugreifen
    if (-not $form -or -not $form.Tag -or -not $form.Tag.Refs) { return $null }

    # Control-Referenz anhand des Namens zurückgeben, oder $null, wenn der Name nicht gefunden wird
    return $form.Tag.Refs[$name]
}


<# CURSOR #>
function Get-Cursor {
    param( [string]$CursorType = "Default" )

    $cursorEnum = switch ($CursorType) {
        "AppStarting" { [Cursors]::AppStarting }
        "Default" {     [Cursors]::Default }
        "Hand" {        [Cursors]::Hand }
        "Wait" {        [Cursors]::WaitCursor }
        default {       [Cursors]::Default }
    }

    return $cursorEnum
}
function Set-Cursor {
    param( [string]$CursorType = "Default" )

    $cursor = Get-Cursor -CursorType $CursorType

    [Cursor]::Current = $cursor
}


<##############################################################################################>
function Get-ProcessLabel {
    param ( $control, [string]$category = "Default" )
    $form = $control.FindForm()

    switch ($category) {
        "Main" { $processLabel = $form.Controls["TabPanel"].Controls["ProcessLabel"]; break }
        "WinGet" { $processLabel = $form.Controls["PackagePanel"].Controls["ProcessLabel"]; break }
        "Chocolatey" { $processLabel = $form.Controls["PackagePanel"].Controls["ProcessLabel"]; break }
         default { $processLabel = $form.Controls.Find("ProcessLabel", $true)[0]; break }
    }

    if (-not $processLabel) { $processLabel = $form.Controls.Find("ProcessLabel", $true)[0] }
    return $processLabel
}
