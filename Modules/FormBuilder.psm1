using namespace System.Windows.Forms
using namespace System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
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
$global:toolTip = & {
    $toolTip = New-Object System.Windows.Forms.ToolTip
    $toolTip.BackColor = $AppColor.Dark
    $toolTip.ForeColor = $AppColor.White
    $toolTip.AutoPopDelay = 5000
    $toolTip.InitialDelay = 500
    $toolTip.ReshowDelay = 500
    $toolTip
}
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
        "TestBG" { "#8E44AD" }
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
    $fontPresets = @{
        Button        = @{ Size = 9;  Name = "Tahoma";          Style = "Bold" }
        Label         = @{ Size = 10; Name = "Tahoma";          Style = "Regular" }
        LabelButton   = @{ Size = 8;  Name = "Consolas";        Style = "Regular" }
        SidebarButton = @{ Size = 8;  Name = "Tahoma";          Style = "Bold" }
        SidebarHeader = @{ Size = 20; Name = "Cascadia Code";   Style = "Bold" }
        SidebarLabel  = @{ Size = 10; Name = "Tahoma";          Style = "Regular" }
        Title         = @{ Size = 18; Name = "Segoe UI";        Style = "Bold" }
        Subtitle      = @{ Size = 13; Name = "Segoe UI";        Style = @("Bold", "Underline") }
    }
    if ($fontPresets.ContainsKey($Control)) {
        $FontSize   = $fontPresets[$Control].Size
        $FontName   = $fontPresets[$Control].Name
        $FontStyle  = $fontPresets[$Control].Style
    } else {
        $FontSize = 10
        $FontName = "Consolas"
        $FontStyle = "Regular"
    }

    # Bevorzugte Schriftarten definieren und die erste verfügbare auswählen
    $Style = If ($Style) { $Style } else { $FontStyle }
    $Size  = If ($Size) { $Size } else { $FontSize }
    $Name  = If ($Name) { $Name } else { $FontName }

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
        & $AppLog.Warn "Icon '$Name' nicht gefunden unter: $iconPath"
        $Name = "Default"
    }

    # Wenn das Standard-Icon nicht gefunden wird, gebe ein leeres Icon zurück
    $iconPath = Join-Path $AppConfig.IconPath "$Name.ico"
    if (-not (Test-Path $iconPath)) {
        & $AppLog.Error "Standard-Icon 'Default' nicht gefunden unter: $iconPath. Es wird kein Icon gesetzt."
        return [Icon]::Application
    }

    # Icon laden und zurückgeben
    return [Icon]::new($iconPath)
}
function Set-Cursor {
    param( [string]$CursorType = "Default" )

    $cursorEnum = switch ($CursorType) {
        "AppStarting" { [System.Windows.Forms.Cursors]::AppStarting }
        "Default" { [System.Windows.Forms.Cursors]::Default }
        "Wait" { [System.Windows.Forms.Cursors]::WaitCursor }
        default { [System.Windows.Forms.Cursors]::Default }
    }

    [System.Windows.Forms.Cursor]::Current = $cursorEnum
}

<##############################################################################################>

<# CONTROLS #>
function New-Button {
    param( [hashtable]$Config = @{} )

    $button = [Button]::new()

    # Default-Stil anwenden
    $button.Height = 30
    $button.FlatStyle = "Flat"
    $button.Cursor = [Cursors]::Hand
    $button.Font = [Font]::new("Consolas", 10)
    $button.ForeColor = $AppColor.Accent
    $button.BackColor = $AppColor.Dark

    # Properties und Events dynamisch setzen
    $events = $button.GetType().GetEvents().Name
    $prop   = $button.GetType().GetProperties().Name
    foreach ($key in $Config.Keys) {
        if ($prop -contains $key) { 
            $button.$key = $Config[$key]
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $button.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $button.$key($Config[$key]) }
        } elseif ($key -eq "ToolTip") {
            if (-not $toolTip) { $toolTip = [ToolTip]::new() }
            $toolTip.SetToolTip($button, $Config[$key])
        }
    }

    $button
}
function New-Label {
    param( [hashtable]$Config = @{} )

    # Mindestanforderungen für Label-Eigenschaften
    $label = [Label]::new()
    $label.Text =  "Labeltext fehlt"
    
    # Properties und Events dynamisch setzen
    $events = $label.GetType().GetEvents().Name
    $prop   = $label.GetType().GetProperties().Name
    foreach ($key in $Config.Keys) {
        if ($prop -contains $key) {
            $label.$key = $Config[$key]
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $label.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $label.$key($Config[$key]) }
        } elseif ($key -eq "ToolTip") {
            if (-not $toolTip) { $toolTip = [ToolTip]::new() }
            $toolTip.SetToolTip($label, $Config[$key])
        } else {
            if ($label.PSObject.Properties[$key]) {
                $label.$key = $Config[$key]
            }
        }
    }

    return $label
}
function New-CheckedListBox {
    param ( [hashtable]$Config = @{} )

    $checkedListBox = [CheckedListBox]::new()

    $checkedListBox.DisplayMember   = "Name"
    $checkedListBox.CheckOnClick    = $true
    $checkedListBox.BorderStyle     = "None"
    $checkedListBox.Font            = [Font]::new("Consolas", 9) 
    $checkedListBox.ForeColor       = $AppColor.White
    $checkedListBox.BackColor       = $AppColor.Dark
    $checkedListBox.Dock            = "Fill"

    # Dynamisch Properties und Events setzen
    $events = $checkedListBox.GetType().GetEvents().Name
    $prop   = $checkedListBox.GetType().GetProperties().Name
    foreach ($key in $Config.Keys) {
        if ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $checkedListBox.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $checkedListBox.$key($Config[$key]) }
        } elseif ($key -eq "ToolTip") {
            if (-not $toolTip) { $toolTip = [ToolTip]::new() }
            $toolTip.SetToolTip($checkedListBox, $Config[$key])
        } elseif ($key -eq "Items") {
            foreach ($program in $Config[$key]) {
                $id = if ($program.PSObject.Properties["Id"]) { $program.Id } elseif ($program.PSObject.Properties["Key"]) { $program.Key } else { $null }
                $name = if ($program.PSObject.Properties["Name"]) { $program.Name } elseif ($program.PSObject.Properties["Value"]) { $program.Value } else { $id }
                $item = [PSCustomObject]@{
                    Id      = $id
                    Name    = $name
                }
                $checkedListBox.Items.Add($item, $false) | Out-Null
            }
        } elseif ($prop -contains $key) { 
            $checkedListBox.$key = $Config[$key]
        } else {
            if ($checkedListBox.PSObject.Properties[$key]) {
                $checkedListBox.$key = $Config[$key]
            }
        }
    }

    $checkedListBox
}
function New-ListBox {
    param ( [hashtable]$Config = @{} )
    $listBox = [ListBox]::new()
    $listBox.BorderStyle = "None"
    $listBox.SelectionMode = "MultiSimple"
    $listBox.DisplayMember = "Name"

    $listBox.ForeColor = $AppColor.White
    $listBox.BackColor = $AppColor.Dark
    $listBox.Font = [Font]::new("Consolas", 10)

    # Dynamisch Properties und Events setzen
    $events = $listBox.GetType().GetEvents().Name
    $props  = $listBox.GetType().GetProperties().Name
    foreach ($key in $Config.Keys) {
        if ($key -eq "ToolTip") {
            if (-not $toolTip) { $script:toolTip = [ToolTip]::new() }
            $toolTip.SetToolTip($listBox, $Config[$key])
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $listBox.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $listBox.$key($Config[$key]) }
        } elseif ($key -eq "Items") {
            Write-Host "Erstelle eine ListBox"
            Write-Host $Config[$key].GetType().FullName
            foreach ($program in $Config[$key]) {
                $item = [PSCustomObject]@{
                    Id      = $program.Key
                    Name    = $program.Value
                }
                $listBox.Items.Add($item) | Out-Null
            }
        } elseif ($props -contains $key) {
            $listBox.$key = $Config[$key]
        } else {
            if ($listBox.PSObject.Properties[$key]) {
                $listBox.$key = $Config[$key]
            }
        }
    }

    $listBox
}
function New-RichTextBox {
    param ( [hashtable]$Config = @{} )

    $richTextBox = [RichTextBox]::new()
    
    $richTextBox.Font        = [Font]::new("Consolas", 10)
    $richTextBox.Text        = "kein Text angegeben"
    $richTextBox.ReadOnly    = $true
    $richTextBox.ForeColor   = $AppColor.White
    $richTextBox.BackColor   = $AppColor.Dark
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
            if (-not $toolTip) { $toolTip = [ToolTip]::new() }
            $toolTip.SetToolTip($richTextBox, $Config[$key])
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

    $textbox = [TextBox]::new()

    # Properties und Events dynamisch setzen
    $events = $textbox.GetType().GetEvents().Name
    $prop   = $textbox.GetType().GetProperties().Name
    foreach ($key in $Config.Keys) {
        if ($prop -contains $key) { 
            $textbox.$key = $Config[$key] 
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $textbox.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $textbox.$key($Config[$key]) }
        } elseif ($key -eq "ToolTip") {
            if (-not $toolTip) { $toolTip = [ToolTip]::new() }
            $toolTip.SetToolTip($textbox, $Config[$key])
        } else {
            if ($textbox.PSObject.Properties[$key]) {
                $textbox.$key = $Config[$key]
            }
        }
    }

    $textbox
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
            if (-not $toolTip) { $toolTip = [ToolTip]::new() }
            $toolTip.SetToolTip($numericUpDown, $Config[$key])
        } else {
            if ($numericUpDown.PSObject.Properties[$key]) {
                $numericUpDown.$key = $Config[$key]
            }
        }
    }

    $numericUpDown
}
function New-ComboBox {
    param ( [hashtable]$Config = @{} )

    $comboBox = [ComboBox]::new()

    $comboBox.DropDownStyle = "DropDownList"
    $comboBox.Font          = [Font]::new("Consolas", 10)
    $comboBox.ForeColor     = $AppColor.White
    $comboBox.BackColor     = $AppColor.Dark

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
            if (-not $toolTip) { $toolTip = [ToolTip]::new() }
            $toolTip.SetToolTip($comboBox, $Config[$key])
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
function New-CheckBox {
    param ( [hashtable]$Config = @{} )

    $checkBox = [CheckBox]::new()

    $checkBox.AutoSize  = $false
    $checkBox.ForeColor = $AppColor.White
    $checkBox.BackColor = $AppColor.Dark
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
            if (-not $toolTip) { $toolTip = [ToolTip]::new() }
            $toolTip.SetToolTip($checkBox, $Config[$key])
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
function New-GroupBox {
    param ( [hashtable]$Config = @{} )

    $groupBox = [GroupBox]::new()
    $groupBox.ForeColor = $AppColor.Accent
    $groupBox.BackColor = $AppColor.Dark
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

<# PANEL #>
function New-FlowLayoutPanel {
    param( [hashtable]$Config = @{} )

    $flowPanel = [FlowLayoutPanel]::new()

    $flowPanel.Dock             = "Fill"
    $flowPanel.AutoScroll       = $false
    $flowPanel.WrapContents     = $false
    $flowPanel.FlowDirection    = "TopDown"
    $flowPanel.ForeColor        = $AppColor.Accent
    $flowPanel.BackColor        = $AppColor.Dark

    # Properties und Events
    $props  = $flowPanel.GetType().GetProperties().Name
    $events = $flowPanel.GetType().GetEvents().Name
    foreach ($key in $Config.Keys) {
        if ($key -eq "Controls") { 
            $ControlConfig = $Config[$key]
            foreach ($item in $ControlConfig.GetEnumerator()) {
                $control        = New-Control $item.Value
                $control.Name   = $item.Key
                $flowPanel.Controls.Add($control)
            }
        
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $flowPanel.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $flowPanel.$key($Config[$key]) }
        } elseif ($props -contains $key) { 
            $flowPanel.$key = $Config[$key] 
        } else {
            if ($flowPanel.PSObject.Properties[$key]) {
                $flowPanel.$key = $Config[$key]
            }
        }
    }

    $flowPanel
}
function New-Panel {
    param( [hashtable]$Config = @{} )

    $panel = [Panel]::new()
    $panel.Dock = "Fill"
    $panel.ForeColor = $AppColor.Accent
    $panel.BackColor = $AppColor.Dark

    # Properties und Events dynamisch setzen
    $events = $panel.GetType().GetEvents().Name
    $prop   = $panel.GetType().GetProperties().Name
    foreach ($key in $Config.Keys) {
        if ($key -eq "Controls") { 
            $ControlConfig = $Config[$key]
            foreach ($cfg in $ControlConfig.GetEnumerator()) {
                $control        = New-Control $cfg.Value
                $control.Name   = $cfg.Key
                $panel.Controls.Add($control)
            }
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $panel.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $panel.$key($Config[$key]) }
        } elseif ($prop -contains $key) { 
            $panel.$key = $Config[$key] 
        } else {
            if ($panel.PSObject.Properties[$key]) {
                $panel.$key = $Config[$key]
            }
        }
        # switch -Wildcard ($key) {
        #     "Controls" { ... }
        #     "Add_*" { ... }
        #     "Remove_*" { ... }
        #     default {
        #         if ($prop -contains $key) { 
        #             ...
        #         } else {
        #             ...
        #         }
        #     }
        # }
    }
    
    $panel
}
function New-TableLayoutPanel {
    param ( $Config = @{} )
    
    $table = [TableLayoutPanel]::new()
    $table.ForeColor = Get-Color "Accent"
    $table.BackColor = Get-Color "Dark"

    # Properties und Events dynamisch setzen
    $type   = $table.GetType()
    $events = $type.GetEvents().Name
    foreach ($key in $Config.Keys) {
        if ($key -eq "Controls") { 
            foreach ($item in $Config[$key].GetEnumerator()) {
                $controlConfig  = $item.Value
                $control        = New-Control $controlConfig
                $control.Name   = $item.Key
                $control.Dock   = "Fill"
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

                    # Spanning
                    if ($colSpan -gt 1) { $table.SetColumnSpan($control, $colSpan) }
                    if ($rowSpan -gt 1) { $table.SetRowSpan($control, $rowSpan) }

                } else { $table.Controls.Add($control) }
                if ($null -ne $controlConfig.ColumnSpan) { $table.SetColumnSpan($control, $controlConfig.ColumnSpan) }
                if ($null -ne $controlConfig.RowSpan)    { $table.SetRowSpan($control, $controlConfig.RowSpan) }
            }
            continue
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $table.$key($Config[$key]) }
            continue
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $table.$key($Config[$key]) }
            continue
        } elseif ($key -in @("Column", "Row")) {
            $keyConfig  = $Config[$key]
            $isColumn   = $key -eq "Column"
            $sizeTypes  = "Percent", "AutoSize", "Absolute"

            if ($isColumn) { $table.ColumnStyles.Clear(); $table.ColumnCount = $keyConfig.Count }
            else { $table.RowStyles.Clear(); $table.RowCount = $keyConfig.Count }

            foreach ($style in $keyConfig) { 
                $keyStyle = if ($style -is [System.Windows.Forms.TableLayoutStyle]) { $style } 
                else {
                    $sizeType   = "AutoSize"
                    $dimension  = 0

                    if ($style -is [string]) {
                        if ($style -match '^\d+$' -and ([int]$style -ge 0 -and [int]$style -le 100)) {
                            $sizeType = "Percent"
                            $dimension = [int]$style
                        } elseif ($sizeTypes -contains $style) {
                            $sizeType = $style
                        }
                    } elseif ($style -is [int]) {
                        $sizeType = "Absolute"
                        $dimension = $style
                    } elseif ($style -is [array]) {
                        if ($style[0] -in $sizeTypes) { $sizeType = $style[0] } 
                        if ($style.Count -gt 1 -and $style[1] -ge 0) { $dimension = $style[1] } 
                    } 

                    if ($isColumn) { [ColumnStyle]::new([SizeType]::$sizeType, $dimension) }
                    else { [RowStyle]::new([SizeType]::$sizeType, $dimension) }

                }
                
                if ($isColumn) { [void]$table.ColumnStyles.Add($keyStyle) }
                else { [void]$table.RowStyles.Add($keyStyle) }
            }
            continue
        } elseif ($key -eq "Position") {
            # Position wird speziell bei Controls innerhalb eines TableLayoutPanels behandelt, daher hier übersprungen
            continue
        } elseif ($key -eq "ToolTip") {
            if (-not $toolTip) { $script:toolTip = [ToolTip]::new() }
            $toolTip.SetToolTip($table, $Config[$key])
            continue
        } elseif ($table.PSObject.Properties.Match($key)) { 
             $table.$key = $Config[$key]
        }
    }    

    # Return
    $table
}

<# TABS #>
function New-TabControl {
    param ( $Config = @{} )
    
    $tabControl = [TabControl]::new()

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
        # switch -Wildcard ($key) {
        #     "Controls" {
        #         $ControlConfig = $Config[$key]
        #         foreach ($item in $ControlConfig.GetEnumerator()) {
        #             $control        = New-Control $item.Value
        #             $control.Name   = $item.Key
        #             $tabControl.Controls.Add($control)
        #         }
        #         continue
        #     }
        #     "Add_*" {
        #         $name = $key.Substring(4) 
        #         if ($events -contains $name) { $tabControl.$key($Config[$key]) }
        #         continue
        #     }
        #     default {
        #         if ($prop -contains $key) { 
        #             $tabControl.$key = $Config[$key] 
        #         }
        #     }
        # }
    }    
    return $tabControl
}   
function New-TabPage {
    param ( $Config = @{} )
    
    $tabPage = [TabPage]::new()
    $tabPage.BorderStyle    = "None"
    $tabPage.BackColor      = $AppColor.Dark
    $tabPage.ForeColor      = $AppColor.Accent
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

<##############################################################################################>

<# FORM #>
function New-Form {
    [CmdletBinding()]
    param( [hashtable]$FormConfig = @{} )
    & $AppLog.Info "Branch: New-Form $($FormConfig.Properties.Text)"

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
    if ($FormConfig.ContainsKey("Properties")) {
        $props = $form.GetType().GetProperties().Name
        foreach ($key in $FormConfig.Properties.Keys) {
            switch ($key) {
                # Spezialbehandlung für ToolTip, da es kein direktes Property des Forms ist, sondern über die SetToolTip-Methode gesetzt wird
                "ToolTip" { 
                    # Setze das ToolTip über die Get-ToolTip Funktion
                    if (-not $toolTip) { $script:toolTip = [ToolTip]::new() }
                    $toolTip.SetToolTip( $form, $FormConfig.Properties[$key] )
                    break
                }
                # Spezialbehandlung für Text, um den Form-Namen voranzustellen (z.B. "Einstellungen – MeinApp")
                "Text" {
                    $formName = ($FormConfig.Properties[$key])
                    $form.Text = "$formName – " + $form.Text
                    break
                }
                default {
                    # Versuche zuerst, die Property direkt zu setzen, wenn sie existiert
                    if ( $props -contains $key) { $form.$key = $FormConfig.Properties[$key] } 
                    elseif ($form.PSObject.Properties.Match($key)) { $form.$key = $FormConfig.Properties[$key] } 
                    else { & $AppLog.Warn "Unbekannte Form-Property: $key" }
                }
            }
        }
    }

    # Controls hinzufügen
    if ($FormConfig.ContainsKey("Controls")) {
        foreach ($controlName in $FormConfig.Controls.Keys) {
            
            # Konfiguration des Controls abrufen
            $controlConfig = $FormConfig.Controls[$controlName]

            # Kontrolle, ob der Control-Typ angegeben ist
            if (-not $controlConfig.ContainsKey("Control")) { & $AppLog.Warn "Control '$controlName' fehlt die Angabe des Control-Typs. Control wird übersprungen."; continue } 

            # Control erstellen und hinzufügen
            $control        = New-Control $controlConfig
            $control.Name   = $controlName
            $form.Controls.Add($control)
        }
    }

    # Events hinzufügen
    if ($FormConfig.ContainsKey("Events")) {
        $events = $form.GetType().GetEvents().Name
        foreach ($key in $FormConfig.Events.Keys) {

            # Präfix "Add_" erkennen, um Event-Handler hinzuzufügen (z.B. "Add_Click" für das Click-Event)
            if ($key -like "Add_*") { 
                $name = $key.Substring(4)
                if ($events -contains $name) { $form.$key($FormConfig.Events[$key]) }
                & $AppLog.Warn "Präfix 'Add_' erkannt. Stelle sicher, dass die Event-Handler korrekt benannt sind: $name"

            # Präfix "Remove_" erkennen, um Event-Handler zu entfernen (z.B. "Remove_Click" für das Click-Event)
            } elseif ($key -like "Remove_*") {
                $name = $key.Substring(7)
                if ($events -contains $name) { $form.$key($FormConfig.Events[$key]) }
                & $AppLog.Warn "Präfix 'Remove_' erkannt. Stelle sicher, dass die Event-Handler korrekt benannt sind: $name"

            # Direkter Event-Name ohne Präfix (z.B. "Click") - in diesem Fall wird angenommen, dass es sich um einen Hinzufügen-Handler handelt
            } elseif ($events -contains $key) {
                $name = "Add_$key"
                $form.$name($FormConfig.Events[$key])
            }
        }
    }

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
    param ( $Config = @{} )
    & $AppLog.Info "Branch: Start-Form"
    
    Set-Cursor "AppStarting"
    $form = New-Form $Config
    
    $form.ShowDialog()
    $form.Dispose()
}

<# FORM CONTROL #>
function New-Control {
    param( [hashtable]$Config )
    if (-not $Config.Control) { throw "Config fehlt das Feld 'Control'" }


    $type = $Config.Control
    $copy = $Config.Clone()
    $copy.Remove("Control")
    
    switch ($type) {
        # Container Controls
        "Panel" {            return New-Panel $copy }
        "FlowLayoutPanel" {  return New-FlowLayoutPanel $copy }
        "TableLayoutPanel" { return New-TableLayoutPanel $copy }
        "GroupBox" {         return New-GroupBox $copy }

        # Standard Controls
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

        # Tab Controls
        "TabControl" { return New-TabControl $copy }
        "TabPage" {    return New-TabPage $copy }

        default { throw "Unbekannter Control-Typ: $type" }

    }
}
function Register-Control {
    param(
        $control,
        [hashtable]$refs
    )

    if ($control.Name) {
        $refs[$control.Name] = $control
    }

    foreach ($child in $control.Controls) {
        Register-Control -control $child -refs $refs
    }
}


<##############################################################################################>
function Get-Ref {
    param($control, $name)

    $form = $control.FindForm()
    if (-not $form -or -not $form.Tag -or -not $form.Tag.Refs) {
        return $null
    }

    return $form.Tag.Refs[$name]
}
function Get-ProcessLabel {
    param ( $s, [string]$category )
    $form = $s.FindForm()

    switch ($category) {
        "Main" { $processLabel = $form.Controls["TabPanel"].Controls["ProcessLabel"]; break }
        "WinGet" { $processLabel = $form.Controls["PackagePanel"].Controls["ProcessLabel"]; break }
        "Chocolatey" { $processLabel = $form.Controls["PackagePanel"].Controls["ProcessLabel"]; break }
         default { $processLabel = $form.Controls.Find("ProcessLabel", $true)[0]; break }
    }

    if (-not $processLabel) { $processLabel = $form.Controls.Find("ProcessLabel", $true)[0] }
    return $processLabel
}






# =============================


function New-ProgressBar {
param ( [hashtable]$Config = @{} )

    $progressBar = [ProgressBar]::new()

    $progressBar.Style     = "Continuous"
    $progressBar.Minimum   = 0
    $progressBar.Maximum   = 100
    $progressBar.Value     = 0
    $progressBar.ForeColor = $AppColor.Accent
    $progressBar.BackColor = $AppColor.Dark

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
            if (-not $toolTip) { $toolTip = [ToolTip]::new() }
            $toolTip.SetToolTip($progressBar, $Config[$key])
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
