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
Add-Type -TypeDefinition @"
using System.Drawing;
using System.Windows.Forms;

public class MyColorTable : ProfessionalColorTable
{
    public override Color ToolStripDropDownBackground => Color.FromArgb(30,30,30);
    public override Color ImageMarginGradientBegin => Color.FromArgb(30,30,30);
    public override Color ImageMarginGradientMiddle => Color.FromArgb(30,30,30);
    public override Color ImageMarginGradientEnd => Color.FromArgb(30,30,30);

    public override Color MenuItemSelected => Color.FromArgb(50,50,50);
    public override Color MenuItemBorder => Color.FromArgb(50,50,50);
}
"@
Add-Type -TypeDefinition @"
using System.Windows.Forms;

public class MyRenderer : ToolStripProfessionalRenderer
{
    public MyRenderer() : base(new MyColorTable()) {}
}
"@

$script:Defaults = @{
    Button = @{
        Height      = 30
        FlatStyle   = "Flat"
        Font        = Get-Font -Control "Button"
        ForeColor   = Get-Color "Accent"
        BackColor   = Get-Color "Dark"
        Cursor      = Get-Cursor "Hand"
    }
    CheckBox = @{
        AutoSize    = $false
        Font        = Get-Font -Control "CheckedListBox"
        ForeColor   = Get-Color "White"
        BackColor   = Get-Color "Dark"
    }
    CheckedListBox = @{
        BorderStyle     = "None"
        DisplayMember   = "Name"
        CheckOnClick    = $true
        Font            = Get-Font -Control "CheckedListBox"
        ForeColor       = Get-Color "White"
        BackColor       = Get-Color "Dark"
    }
    ComboBox = @{
        DropDownStyle   = "DropDownList"
        Font            = Get-Font -Control "ComboBox"
        ForeColor       = Get-Color "White"
        BackColor       = Get-Color "Dark"
    }
    ContextMenu = @{
        ForeColor       = Get-Color "Accent"
        # BackColor       = Get-Color "Dark"
        ShowImageMargin = $true
        Add_Opening = {
            param($src, $e)
            $sourceControl  = $src.SourceControl
            $e.Cancel       = -not $sourceControl -or $sourceControl.SelectedItems.Count -eq 0
        }
    }
    FlowLayoutPanel = @{
        Dock            = "Fill"
        AutoScroll      = $false
        WrapContents    = $false
        FlowDirection   = "TopDown"
        ForeColor       = Get-Color "Accent"
        BackColor       = Get-Color "Dark"
    }
    Form = @{
        StartPosition   = "CenterScreen"
        BackColor       = Get-Color "Accent"
        ForeColor       = Get-Color "Dark"
        Padding         = [Padding]::new(10)
        MaximizeBox     = $false
        Text            = $AppInfo.Name
        Icon            = "Default"

        # FormBorderStyle = "FixedSingle"
        # MinimizeBox     = $false
        # ShowIcon        = $true
        # ShowInTaskbar   = $true
    }
    GroupBox = @{
        ForeColor   = Get-Color "Accent"
        BackColor   = Get-Color "Dark"
        Font        = Get-Font -Control "GroupBox"
        Dock        = "Fill"
    }
    Label = @{
        Text        = "New-Label Text"
        Font        = Get-Font -Control "Label"
        TextAlign   = "MiddleCenter"
    }
    ListBox = @{
        BorderStyle     = "None"
        DisplayMember   = "Name"
        Font            = Get-Font -Control "ListBox"
        ForeColor       = Get-Color "White"
        BackColor       = Get-Color "Dark"
        Dock            = "Fill"
        SelectionMode   = "MultiExtended"
    }
    ListView = @{
        BorderStyle     = "None"
        View            = [System.Windows.Forms.View]::Details
        FullRowSelect   = $true
        GridLines       = $false
        Font            = Get-Font -Control "ListView"
        ForeColor       = Get-Color "White"
        BackColor       = Get-Color "Dark"
        ColumnsHeader   = @{
            BackColor   = Get-Color "Accent"
            ForeColor   = Get-Color "Dark"
            Font        = Get-Font -Control "ListView"
        }
    }
    NumericUpDown = @{
        BackColor   = Get-Color "Dark"
        ForeColor   = Get-Color "Accent"

    }
    Panel = @{
        Dock        = "Fill"
        ForeColor   = Get-Color "Accent"
        BackColor   = Get-Color "Dark"
    }
    ProgressBar = @{
        Style       = "Continuous"
        ForeColor   = Get-Color "Accent"
        BackColor   = Get-Color "Dark"
        Value       = 0
        Minimum     = 0
        Maximum     = 100
    }
    RichTextBox = @{
        Text        = "RichTextBox ohne Text"
        BorderStyle = "None"
        Font        = Get-Font -Control "RichTextBox"
        ForeColor   = Get-Color "White"
        BackColor   = Get-Color "Dark"
        ReadOnly    = $true
    }
    TabControl = @{
        Dock        = "Fill"
        ForeColor   = Get-Color "Accent"
        BackColor   = Get-Color "Dark"
        Font        = Get-Font -Control "TabControl"
    }
    TableLayoutPanel = @{
        Dock        = "Fill"
        ForeColor   = Get-Color "Accent"
        BackColor   = Get-Color "Dark"
    }
    TabPage = @{
        BorderStyle   = "None"
        ForeColor   = Get-Color "Accent"
        BackColor   = Get-Color "Dark"
        Font        = Get-Font -Control "TabPage"
    }
    TextBox = @{
        BorderStyle = "None"
        Font        = Get-Font -Control "TextBox"
        Dock        = "Fill"
        ForeColor   = Get-Color "Accent"
        BackColor   = Get-Color "Dark"
    }
}


function Convert-ToSize($size) {
    if ($size -is [System.Drawing.Size]) { return $size }

    if ($size -is [string] -and $size -match '^(\d+)x(\d+)$') { return [System.Drawing.Size]::new([int]$Matches[1], [int]$Matches[2]) }

    if ($size -is [System.Collections.IEnumerable]) {
        $arr = @($size)
        if ($arr.Count -eq 2 -and $arr[0] -as [int] -and $arr[1] -as [int]) {
            return [System.Drawing.Size]::new([int]$arr[0], [int]$arr[1])
        }
    }

    throw "Ungültiges Size-Format: $size"
}

function Merge-Config {
    param( [hashtable]$DefaultConfig, [hashtable]$CustomConfig )

    $merged = @{}

    # foreach ($hash in $Configs) {
    foreach ($config in @($DefaultConfig, $CustomConfig)) {
        if (-not $config) { continue }

        foreach ($key in $config.Keys) { $merged[$key] = $config[$key] }
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
    $toolTip = [ToolTip]::new()
    $toolTip.BackColor = Get-Color "Dark"
    $toolTip.ForeColor = Get-Color "White"
    $toolTip.AutoPopDelay = 5000
    $toolTip.InitialDelay = 500
    $toolTip.ReshowDelay = 500
    return $toolTip
}
function Show-Tooltip {
    param( [Control]$Control, [string]$Message, [int]$Duration = 2000 )
    $ToolTip.Show($Message, $Control, $Duration)
}

<### CONTEXT-MENU ###>
function New-ContextMenu {
    param( [hashtable]$Config = @{} )
    $contextMenu = [ContextMenuStrip]::new()
    $contextMenu.Renderer = [MyRenderer]::new()
    $Config = Merge-Config -DefaultConfig $script:Defaults.ContextMenu -CustomConfig $Config

    $type   = $contextMenu.GetType()
    $props  = $type.GetProperties().Name
    $events = $type.GetEvents().Name

    foreach ($key in $Config.Keys) {
        if ($key -eq "Items") { 
            $itemConfig = $Config[$key]
            foreach ($cfg in $itemConfig.GetEnumerator()) {
                $menuItem        = New-MenuItem $cfg.Value
                $menuItem.Name   = $cfg.Key
                [void]$contextMenu.Items.Add($menuItem)
            }
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $contextMenu.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $contextMenu.$key($Config[$key]) }
        } elseif ($props -contains $key) { 
            $contextMenu.$key = $Config[$key] 
        } elseif ($contextMenu.PSObject.Properties[$key]) {
            $contextMenu.$key = $Config[$key]
        }
    }

    return $contextMenu
}
function New-MenuItem {
    param( [hashtable]$Config = @{} )
    $menuItem = [ToolStripMenuItem]::new()

    $type   = $menuItem.GetType()
    $props  = $type.GetProperties().Name
    $events = $type.GetEvents().Name

    foreach ($key in $Config.Keys) {
        if ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $menuItem.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $menuItem.$key($Config[$key]) }
        } elseif ($key -eq "Image") {
            $menuItem.Image = Get-Image $Config[$key] $PSScriptRoot
        } elseif ($props -contains $key) { 
            $menuItem.$key = $Config[$key] 
        } elseif ($menuItem.PSObject.Properties[$key]) {
            $menuItem.$key = $Config[$key]
        }

    }
    return $menuItem
}

<### LAYOUT-CONTAINER ###>
function New-Panel {
    param( [hashtable]$Config = @{} )
    $panel   = [Panel]::new()

    # Properties und Events dynamisch setzen
    $type   = $panel.GetType()
    $events = $type.GetEvents().Name
    $prop   = $type.GetProperties().Name

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
    }
    
    # Return
    return $panel
}
function New-FlowLayoutPanel {
    param( [hashtable]$Config = @{} )
    $flowPanel  = [FlowLayoutPanel]::new()

    # Properties und Events dynamisch setzen
    $type   = $flowPanel.GetType()
    $props  = $type.GetProperties().Name
    $events = $type.GetEvents().Name

    foreach ($key in $Config.Keys) {
        if ($key -eq "Controls") { 
            $ControlConfig = $Config[$key]
            foreach ($cfg in $ControlConfig.GetEnumerator()) {
                $control        = New-Control $cfg.Value
                $control.Name   = $cfg.Key
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
        } elseif ($flowPanel.PSObject.Properties[$key]) {
            $flowPanel.$key = $Config[$key]
        }
    }

    # Return
    return $flowPanel
}
function New-TableLayoutPanel {
    param ( $Config = @{} )
    $table  = [TableLayoutPanel]::new()

    # Properties und Events dynamisch setzen
    $type   = $table.GetType()
    $events = $type.GetEvents().Name
    $props  = $type.GetProperties().Name

    foreach ($key in $Config.Keys) {
        if ($key -eq "Controls") { 
            foreach ($cfg in $Config[$key].GetEnumerator()) {
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
            if ($events -contains $name) { $table.$key($Config[$key]) }
            continue
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $table.$key($Config[$key]) }
            continue
        } elseif ($key -in @("Column", "Row")) {
            # Spezialbehandlung für RowStyles und ColumnStyles, da diese komplexe Objekte sind und nicht direkt über die Property gesetzt werden können
            $keyConfig  = $Config[$key]
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
            $ToolTip.SetToolTip($table, $Config[$key])
            continue
        } elseif ($props -contains $key) { 
            $table.$key = $Config[$key] 
        } elseif ($table.PSObject.Properties[$key]) {
            $table.$key = $Config[$key]
        }
    }    

    # Return
    $table
}


<### STRUKTUR-CONTAINER ###>
function New-GroupBox {
    param ( [hashtable]$Config = @{} )
    $groupBox   = [GroupBox]::new()


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
        } elseif ($groupBox.PSObject.Properties[$key]) {
            $groupBox.$key = $Config[$key]
        }
    }

    # Return
    return $groupBox
}
function New-TabControl {
    param ( $Config = @{} )
    $tabControl     = [TabControl]::new()

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


<### LEAF CONTROLS ###>
function New-Button {
    param( [hashtable]$Config = @{} )
    $button = [Button]::new()


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
    $checkedListBox = [CheckedListBox]::new()
    $Config         = Merge-Config $Defaults.CheckedListBox $Config
    

    # Dynamisch Properties und Events setzen
    $type   = $checkedListBox.GetType()
    $events = $type.GetEvents().Name
    $prop   = $type.GetProperties().Name

    foreach ($key in $Config.Keys) {
        if ($key -like "Add_*") { 
            $name = $key.Substring(4) # Eventnamen extrahieren, z.B. "SelectedIndexChanged" aus "Add_SelectedIndexChanged"
            if ($events -contains $name) { $checkedListBox.$key($Config[$key]) }
            continue
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) # Eventnamen extrahieren, z.B. "SelectedIndexChanged" aus "Remove_SelectedIndexChanged"
            if ($events -contains $name) { $checkedListBox.$key($Config[$key]) }
            continue
        } elseif ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($checkedListBox, $Config[$key])
            continue
        } elseif ($key -eq "Items") {
            foreach ($program in $Config[$key]) {
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
            $checkedListBox.$key = $Config[$key]
            continue
        } elseif ($checkedListBox.PSObject.Properties[$key]) { 
            $checkedListBox.$key = $Config[$key] 
        }
    }

    # Return
    return $checkedListBox
}
function New-ComboBox {
    param ( [hashtable]$Config )
    $comboBox   = [ComboBox]::new()
    $Config     = Merge-Config $Defaults.ComboBox $Config
    $deferredSelectedIndex = $null

    # Properties und Events dynamisch setzen
    $type   = $comboBox.GetType()
    $events = $type.GetEvents().Name
    $prop   = $type.GetProperties().Name

    foreach ($key in $Config.Keys) {
        if ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($comboBox, $Config[$key])
        } elseif ($key -like "Add_*") {
            $name = $key.Substring(4)
            if ($events -contains $name) { $comboBox.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") {
            $name = $key.Substring(7)
            if ($events -contains $name) { $comboBox.$key($Config[$key]) }
        } elseif ($key -eq "Items") {
            foreach ($item in $Config[$key]) { [void]$comboBox.Items.Add($item) }
        } elseif ($key -eq "SelectedIndex") {
            # Erst nach Items setzen, sonst ist 0 ungueltig, wenn Items noch leer sind.
            $deferredSelectedIndex = [int]$Config[$key]
        } elseif ($prop -contains $key) {
            $comboBox.$key = $Config[$key]
        } elseif ($comboBox.PSObject.Properties[$key]) {
            $comboBox.$key = $Config[$key]
        }
    }

    if (($deferredSelectedIndex) -and ($comboBox.Items.Count -gt 0)) {
        if ($deferredSelectedIndex -ge 0 -and $deferredSelectedIndex -lt $comboBox.Items.Count) {
            $comboBox.SelectedIndex = $deferredSelectedIndex
        }
    } else {
        $comboBox.Items.Add("Keine Einträge") | Out-Null
        $comboBox.SelectedIndex = 0
    }

    $comboBox
}
function New-Label {
    param( [hashtable]$Config = @{}  )
    $label  = [Label]::new()
    
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
    $listBox = [ListBox]::new()

    # Dynamisch Properties und Events setzen
    $type   = $listBox.GetType()
    $events = $type.GetEvents().Name
    $props  = $type.GetProperties().Name

    foreach ($key in $Config.Keys) {
        if ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($listBox, $Config[$key])
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $listBox.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $listBox.$key($Config[$key]) }
        } elseif ($key -eq "Items") {
            foreach ($program in $Config[$key]) {
                $item = [PSCustomObject]@{
                    Id      = $program.Key
                    Name    = $program.Value
                }
                [void]$listBox.Items.Add($item)
            }
        } elseif ($props -contains $key) {
            $listBox.$key = $Config[$key]
        } elseif ($listBox.PSObject.Properties[$key]) {
            $listBox.$key = $Config[$key]
        }
    }

    # Return
    return $listBox
}
function New-ListView {
    param ( [hashtable]$Config = @{} )
    $listView = [ListView]::new()
    
    # Dynamisch Properties und Events setzen
    $type   = $listView.GetType()
    $type.GetProperty("DoubleBuffered", [System.Reflection.BindingFlags] "NonPublic,Instance").SetValue($listView, $true, $null)
    $events = $type.GetEvents().Name
    $props  = $type.GetProperties().Name

    foreach ($key in $Config.Keys) {
        switch -Wildcard ($key) {
            "ToolTip" {
                $ToolTip.SetToolTip($listView, $Config[$key])
                break
            }
            "Add_*" {
                $name = $key.Substring(4)
                if ($events -contains $name) { $listView.$key($Config[$key]) }
                break
            }
            "Remove_*" {
                $name = $key.Substring(7)
                if ($events -contains $name) { $listView.$key($Config[$key]) }
                break
            }
            "Items" {
                foreach ($program in $Config[$key]) {
                    $id   = if ($program.PSObject.Properties["Id"]) { $program.Id } elseif ($program.PSObject.Properties["Key"]) { $program.Key } else { $null }
                    $name = if ($program.PSObject.Properties["Name"]) { $program.Name } elseif ($program.PSObject.Properties["Value"]) { $program.Value } else { [string]$id }
                    $lvItem = [System.Windows.Forms.ListViewItem]::new([string]$name)
                    $lvItem.Tag = $id
                    [void]$listView.Items.Add($lvItem)
                }
                break
            }
            "Columns" {
                foreach ($col in $Config[$key]) {
                    $header = if ($col -is [string]) { $col } elseif ($col.Text) { $col.Text } elseif ($col[0]) { [string]$col[0] } else { [string]$col }
                    $width  = if ($col.Width) { $col.Width } elseif ($col[1]) { [int]$col[1] } else { -2 }
                    [void]$listView.Columns.Add($header, $width)
                }
                break
            }
            "ColumnsHeader" {
                $listView.Tag = $Config[$key]
                $listView.OwnerDraw = $true
                $listView.Add_DrawColumnHeader({ param($listView, $e) Get-DrawColumnHeader -ListView $listView -e $e -Config $listView.Tag })
                $listView.add_DrawItem({ param($listView, $e) Get-DrawItem -ListView $listView -e $e })
                $listView.add_DrawSubItem({ param($listView, $e) Get-DrawSubItem -ListView $listView -e $e })
            }
            default {
                if ($props -contains $key) {
                    $listView.$key = $Config[$key]
                } elseif ($listView.PSObject.Properties[$key]) {
                    $listView.$key = $Config[$key]
                }
            }
        }
    }

    # Return
    return $listView
}
function New-ListViewItem {
    param ( [string]$Text, [array]$SubItems = @() )
    $item = [System.Windows.Forms.ListViewItem]::new($Text)
    foreach ($subItem in $SubItems) { [void]$item.SubItems.Add([string]$subItem) }
    return $item
}
function New-NumericUpDown {
    param ( [hashtable]$Config = @{} )
    $numericUpDown = [NumericUpDown]::new()
    # $numericUpDown.Controls[0].Visible = $false # Pfeile ausblenden

    # Properties und Events dynamisch setzen
    $type   = $numericUpDown.GetType()
    $events = $type.GetEvents().Name
    $prop   = $type.GetProperties().Name

    foreach ($key in $Config.Keys) {
        if ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($numericUpDown, $Config[$key])
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $numericUpDown.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $numericUpDown.$key($Config[$key]) }
        } elseif ($prop -contains $key) { 
            $numericUpDown.$key = $Config[$key] 
        } elseif ($numericUpDown.PSObject.Properties[$key]) {
            $numericUpDown.$key = $Config[$key]
        }
    }

    # Return
    return $numericUpDown
}
function New-ProgressBar {
    param ( [hashtable]$Config = @{} )
    $progressBar = [ProgressBar]::new()

    # Properties und Events dynamisch setzen
    $type   = $progressBar.GetType()
    $events = $type.GetEvents().Name
    $prop   = $type.GetProperties().Name

    foreach ($key in $Config.Keys) {
        if ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($progressBar, $Config[$key])
        } elseif ($key -like "Add_*") {
            $name = $key.Substring(4)
            if ($events -contains $name) { $progressBar.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") {
            $name = $key.Substring(7)
            if ($events -contains $name) { $progressBar.$key($Config[$key]) }
        } elseif ($prop -contains $key) {
            $progressBar.$key = $Config[$key]
        } elseif ($progressBar.PSObject.Properties[$key]) {
            $progressBar.$key = $Config[$key]
        }
    }

    # Return
    return $progressBar
}
function New-RichTextBox {
    param ( [hashtable]$Config = @{} )
    $richTextBox = [RichTextBox]::new()

    # Properties und Events dynamisch setzen
    $type   = $richTextBox.GetType()
    $prop   = $type.GetProperties().Name
    $events = $type.GetEvents().Name

    foreach ($key in $Config.Keys) {
        if ($key -eq "ToolTip") {
            $ToolTip.SetToolTip($richTextBox, $Config[$key])
        } elseif ($key -like "Add_*") { 
            $name = $key.Substring(4) 
            if ($events -contains $name) { $richTextBox.$key($Config[$key]) }
        } elseif ($key -like "Remove_*") { 
            $name = $key.Substring(7) 
            if ($events -contains $name) { $richTextBox.$key($Config[$key]) }
        } elseif ($prop -contains $key) { 
            $richTextBox.$key = $Config[$key] 
        } elseif ($richTextBox.PSObject.Properties[$key]) {
            $richTextBox.$key = $Config[$key]
        }
    }
    
    # Return
    return $richTextBox
}
function New-TextBox {
    param ( [hashtable]$Config = @{} )
    $textbox = [TextBox]::new()

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
        } elseif ($textbox.PSObject.Properties[$key]) { 
            $textbox.$key = $Config[$key] 
        }
    }

    # Return
    return $textbox
}


<# FORM #>
function New-Form {
    param( [hashtable]$Config = @{} )
    $form = [Form]::new()
    $Config.Properties = Merge-Config $Defaults.Form $Config.Properties

    # Properties dynamisch setzen
    if ($Config.ContainsKey("Properties")) {
        $props = $form.GetType().GetProperties().Name
        foreach ($key in $Config.Properties.Keys) {
            switch ($key) {
                # Spezialbehandlung für Text, um den Form-Namen voranzustellen (z.B. "Einstellungen – MeinApp")
                "Text" {
                    $formName   = $Config.Properties[$key]

                    # Wenn der Form-Name "-only" enthält, füge den Standard-Form-Namen nicht hinzu
                    if ($formName -like "*-only*") { $form.Text = $formName -replace "-only", "" }
                    elseif ($formName -eq $Defaults.Form.Text) { $form.Text = $formName }
                    else { $form.Text = "$formName - $($Defaults.Form.Text)" }
                    continue
                }
                "Icon"       { $form.Icon = Get-icon -Name $Config.Properties[$key] -ScriptRoot $PSScriptRoot; break }
                "ClientSize" { $form.ClientSize = Convert-ToSize $Config.Properties[$key]; break }
                default {
                    # Versuche zuerst, die Property direkt zu setzen, wenn sie existiert
                    if ( $props -contains $key) { $form.$key = $Config.Properties[$key] } 
                    elseif ($form.PSObject.Properties.Match($key)) { $form.$key = $Config.Properties[$key] } 
                    else { Write-Warning "Unbekannte Form-Property: $key" }
                }
            }
        }
        if (-not $Config.Properties["Icon"] -and $Config.Properties["Text"]) {
            $form.Icon = if ($Config.Properties["Text"] -like "*Office*") { Get-icon -Name "Office" -ScriptRoot $PSScriptRoot }
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
    param ( $Config = @{} )
    
    Set-Cursor "AppStarting"
    $form = New-Form $Config
    
    $form.ShowDialog() 
    $form.Dispose()
}

<# CONTROL #>
function New-Control {
    param( [hashtable]$Config )
    if (-not $Config.Control) { throw "Config fehlt das Feld 'Control'" }


    # Control-Typ ermitteln und Control erstellen
    $type = $Config.Control
    $copy = $Config.Clone()
    $copy = Merge-Config $Defaults.$type $copy
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
        
        # Leaf Controls
        "Button" {         return New-Button $copy }
        "CheckBox" {       return New-CheckBox $copy }
        "Label"  {         return New-Label $copy }
        "NumericUpDown" {  return New-NumericUpDown $copy }
        "ProgressBar" {    return New-ProgressBar $copy }
        "RichTextBox" {    return New-RichTextBox $copy }
        "TextBox" {        return New-TextBox $copy }
        
        # List Controls
        "CheckedListBox" { return New-CheckedListBox $copy }
        "ComboBox" {       return New-ComboBox $copy }
        "ListBox" {        return New-ListBox $copy }
        "ListView" {       return New-ListView $copy }
        
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
function Test-Control {
    param( $control )
    Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name) | Control: $($control.Name)"
    if ($null -eq $control -or $control.IsDisposed) { 
        Write-Debug "[EXIT] $($MyInvocation.MyCommand.Name) - Control ist null oder bereits disposed."; 
        return $false 
    } 
    
    Write-Debug "[EXIT] $($MyInvocation.MyCommand.Name) - Control '$($control.Name)' ist gültig."
    return $true 
}



<# PowerStatusForm #>
function Update-ProcessLabel {
    param( 
        [Parameter(Mandatory = $true)]$Control, # $this-Objekt, um auf die Steuerelemente zuzugreifen
        [string]$Message,                       # Die Nachricht, die im Label angezeigt werden soll
        [int]$Delay = 0,                        # Optionale Verzögerung in Sekunden, bevor die Nachricht aktualisiert wird
        [switch]$Final                          # Optionaler Schalter, der angibt, ob dies die letzte Aktualisierung ist (z. B. nach Abschluss eines Prozesses)
    )
    # Überprüfen, ob der Aufruf von einem anderen Thread stammt, und gegebenenfalls den Aufruf auf den UI-Thread verschieben.
    Write-Debug "Prüfe, ob der Aufruf von einem anderen Thread stammt: InvokeRequired = $($Control.InvokeRequired)"
    if ($Control.InvokeRequired) {
        $Control.Invoke({ param($l, $m, $d, $f) Update-ProcessLabel -Control $l -Message $m -Delay $d -Final:$f }, $Control, $Message, $Delay, $Final)
        return
    }

    
    $label = if ($Control.Name -eq "ProcessLabel") { $Control } else { Get-Control $Control "ProcessLabel" }
    
    # Aktualisiert den Text des Labels mit der übergebenen Nachricht und erzwingt die Aktualisierung der Benutzeroberfläche.
    Write-Debug "[UPDATE] Aktualisiere Label-Text: $Message"
    $label.Text = $Message
    [Application]::DoEvents()
    
    # Stellt sicher, dass das Label sichtbar wird, wenn der Status aktualisiert wird.
    if ($label.Visible -eq $false) {
        Write-Debug "[UPDATE] Ändere Sichtbarkeit des Labels auf sichtbar, da es derzeit ausgeblendet ist."
        $label.Visible = $true 
        Set-Cursor "Wait"
    }

    # Delay falls angegeben
    Start-Sleep -Seconds $Delay

    # Wenn der Final-Parameter gesetzt ist, wird das Label nach einer kurzen Verzögerung ausgeblendet.
    if ($Final) {
        Write-Debug "Final-Parameter ist gesetzt. Blende Label nach $Delay Sekunden aus."
        Start-Sleep -Seconds $Delay
        Set-Cursor "Default"
        $label.Visible = $false
    }
}
function Show-PowerStatusForm {
    param( [string]$GroupBoxText, [int]$CurrentMinutes, $PowerScheme, $StatusType )

    $FormConfig = @{
        Properties = @{
            Text        = "Energieoptionen Ändern"
            ClientSize  = [Size]::new(280,60)
            MinimizeBox = $false
            MaximizeBox = $false
            KeyPreview  = $true
            FormBorderStyle = "FixedDialog"
            Padding     = [Padding]::new(5)
            BackColor   = Get-Color "Dark"
            Icon       = "PowerStatus"
        }
        Controls = [ordered]@{
            GroupBox = @{
                Control     = "GroupBox"
                Text        = $GroupBoxText
                Controls    = [ordered]@{
                    TestTable = @{
                        Control     = "TableLayoutPanel"
                        Dock        = "Fill"
                        Column      = @(50, "AutoSize", "40")
                        Row         = @(30)
                        Controls    = [ordered]@{
                            Minutes = @{
                                Control     = "NumericUpDown"
                                Value       = $CurrentMinutes
                                Dock        = "Fill"
                                Minimum     = 0
                                Increment   = 5
                                Maximum     = 999
                                Add_KeyPress = { 
                                    # Akzeptiere nur Ziffern
                                    if (-not [char]::IsDigit($_.KeyChar) -and $_.KeyChar -ne [char]8) { $_.Handled = $true } 
                                    # Begrenze die Eingabe auf maximal 3 Zeichen
                                    elseif ($this.Text.Length -ge 3 -and $_.KeyChar -ne [char]8) { $_.Handled = $true }
                                }
                            }
                            MinutesLabel = @{
                                Control     = "Label"
                                Text        = "Minuten"
                                Dock        = "Fill"
                                TextAlign   = "MiddleLeft"
                            }
                            ChangeButton = @{
                                Control     = "Button"
                                Name        = "ChangeButton"
                                Text        = "Ändern"
                                Dock        = "Fill"
                                Add_Click    = {
                                    $form = $this.FindForm()
                                    [int]$minutes = $this.Parent.Controls["Minutes"].Text
                                    Set-PowerStatus -PowerScheme $PowerScheme -StatusType $StatusType -Minutes $minutes
                                    $form.Close()
                                }
                            }
                        }
                    }
                }
            }
        }
        Events = @{
            KeyDown = {
                # Bestätigt die Eingabe, wenn die Enter-Taste gedrückt wird, aber nur wenn der Fokus auf dem Minuten-Textfeld liegt
                if ($this.ActiveControl.Name -eq "Minutes") {
                    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                        $this.Controls["GroupBox"].Controls["TestTable"].Controls["ChangeButton"].PerformClick()
                    }
                }
            }
        }
    }

    Start-Form $FormConfig
}


<# Forms dot-source #>
$FormsPath = Join-Path $PSScriptRoot "Forms"
Get-ChildItem -Path $FormsPath -Filter "*.psm1" | ForEach-Object { Import-Module $_.FullName }