function Get-DrawColumnHeader {
    param(
        [System.Windows.Forms.ListView]$ListView,
        [System.Windows.Forms.DrawListViewColumnHeaderEventArgs]$e,
        [hashtable]$Config = @{
            Font        = Get-Font -Control "ListView"
            ForeColor   = Get-Color "Dark"
            BackColor   = Get-Color "Accent"
            TextAlign   = "MiddleLeft"
            Ellipsis    = $true
        }
    )
    $ListView.OwnerDraw = $true
    $e.DrawDefault = $false
    $headerBounds   = $e.Bounds
    $graphics       = $e.Graphics

    # Hintergrund zeichnen
    $BackColor = if ($Config.BackColor) { [SolidBrush]::new($Config.BackColor) } else { [SolidBrush]::new($ListView.BackColor) }
    $graphics.FillRectangle($BackColor, $headerBounds)

    # Text zeichnen
    $text       = [string]$e.Header.Text
    $textColor  = if ($Config.ForeColor) { $Config.ForeColor } else { $ListView.ForeColor }
    $textFont   = if ($Config.Font) { $Config.Font } else { $ListView.Font }

    # Location & Größe des Textes
    $textX      = $headerBounds.X + 6       # Location.X – Abstand vom linken Rand des Headers
    $textY      = $headerBounds.Y           # Location.Y – Abstand vom oberen Rand des Headers
    $textWidth  = $headerBounds.Width - 12  # Width – Breite des Headers
    $textHeight = $headerBounds.Height      # Height – Höhe des Headers
    $textBounds = [System.Drawing.Rectangle]::new($textX, $textY, $textWidth, $textHeight)

    # Text-Ausrichtung
    $textFlags = switch($Config.TextAlign) {
        "MiddleLeft"   { [System.Windows.Forms.TextFormatFlags]::Left -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter }
        "MiddleRight"  { [System.Windows.Forms.TextFormatFlags]::Right -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter }
        "MiddleCenter" { [System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter }
        "TopLeft"      { [System.Windows.Forms.TextFormatFlags]::Left -bor [System.Windows.Forms.TextFormatFlags]::Top }
        "TopRight"     { [System.Windows.Forms.TextFormatFlags]::Right -bor [System.Windows.Forms.TextFormatFlags]::Top }
        "TopCenter"    { [System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor [System.Windows.Forms.TextFormatFlags]::Top }
        "BottomLeft"   { [System.Windows.Forms.TextFormatFlags]::Left -bor [System.Windows.Forms.TextFormatFlags]::Bottom }
        "BottomRight"  { [System.Windows.Forms.TextFormatFlags]::Right -bor [System.Windows.Forms.TextFormatFlags]::Bottom }
        "BottomCenter" { [System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor [System.Windows.Forms.TextFormatFlags]::Bottom }
        default        { [System.Windows.Forms.TextFormatFlags]::Left -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter }
    }

    if ($Config.Ellipsis) { $textFlags = $textFlags -bor [System.Windows.Forms.TextFormatFlags]::EndEllipsis }
    [TextRenderer]::DrawText($graphics, $text, $textFont, $textBounds, $textColor, $textFlags)
}
function Get-DrawItem {
    param(
        [System.Windows.Forms.ListView]$ListView,
        [System.Windows.Forms.DrawListViewItemEventArgs]$e,
        [hashtable]$Config = @{
            BackColor   = Get-Color "Accent"
        }
    )
    $graphics   = $e.Graphics
    $itemBounds = $e.Bounds

    # Hintergrund zeichnen
    $itemBackground = if ($e.Item.Selected) { [SolidBrush]::new($Config.BackColor) } 
                        else { [SolidBrush]::new($ListView.BackColor) }
    $graphics.FillRectangle($itemBackground, $itemBounds)
    $e.DrawFocusRectangle()
}
function Get-DrawSubItem {
    param(
        [System.Windows.Forms.ListView]$ListView,
        [System.Windows.Forms.DrawListViewSubItemEventArgs]$e
    )
    $graphics       = $e.Graphics
    $subItemBounds  = $e.Bounds

    $BackColor  = if ($e.Item.Selected) { Get-Color "Accent" } else { $ListView.BackColor }
    $BackColor  = [SolidBrush]::new($BackColor)
    $graphics.FillRectangle($BackColor, $subItemBounds)

    $ForeColor  = if ($e.Item.Selected) { Get-Color "Dark" } else { $ListView.ForeColor }
    $ForeColor  = [SolidBrush]::new($ForeColor)
    $stringFormat = [StringFormat]::new()

    # Location & Größe des Textes
    $textX      = $subItemBounds.X + 2      # Location.X – Abstand vom linken Rand des SubItems
    $textY      = $subItemBounds.Y       # Location.Y – Abstand vom oberen Rand des SubItems
    $textWidth  = $subItemBounds.Width - 2   # Width – Breite des SubItems
    $textHeight = $subItemBounds.Height  # Height – Höhe des SubItems
    $textBounds = [System.Drawing.RectangleF]::new($textX, $textY, $textWidth, $textHeight)
    
    
    $stringFormat.LineAlignment = [StringAlignment]::Center
    $stringFormat.Trimming = [StringTrimming]::EllipsisCharacter
    $graphics.DrawString($e.SubItem.Text, $ListView.Font, $ForeColor, $textBounds, $stringFormat)
}