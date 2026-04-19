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

    # In der Details-Ansicht werden Hintergrund und Text pro SubItem gezeichnet.
    # Ein zeilenweites Übermalen hier kann beim Hover SubItems unsichtbar machen.
    if ($ListView.View -eq [System.Windows.Forms.View]::Details) {
        if ($e.Item.Selected -and $ListView.Focused) {
            $e.DrawFocusRectangle()
        }
        return
    }

    # Hintergrund zeichnen
    $itemBackground = if ($e.Item.Selected) { [SolidBrush]::new($Config.BackColor) } 
                        else { [SolidBrush]::new($ListView.BackColor) }
    $graphics.FillRectangle($itemBackground, $itemBounds)
    $e.DrawFocusRectangle()
    $itemBackground.Dispose()
}
function Get-DrawSubItem {
    param(
        [System.Windows.Forms.ListView]$ListView,
        [System.Windows.Forms.DrawListViewSubItemEventArgs]$e
    )
    $graphics       = $e.Graphics
    $Bounds         = $e.Bounds
    $isSelected     = $e.Item.Selected

    $backColorValue = if ($isSelected) { Get-Color "Accent" } else { $ListView.BackColor }
    $foreColorValue = if ($isSelected) { Get-Color "Dark" } else { $ListView.ForeColor }

    $backColorBrush = [SolidBrush]::new($backColorValue)
    try {
        $graphics.FillRectangle($backColorBrush, $Bounds)
    } finally {
        $backColorBrush.Dispose()
    }

    # Location & Größe des Textes
    $text = if ($e.ColumnIndex -eq 0) { $e.Item.Text } else { $e.SubItem.Text }
    $textBounds = [System.Drawing.Rectangle]::new(
        $Bounds.X + 2,
        $Bounds.Y,
        [Math]::Max(0, $Bounds.Width - 2),
        $Bounds.Height
    )

    [System.Windows.Forms.TextRenderer]::DrawText(
        $graphics,
        $text,
        $ListView.Font,
        $textBounds,
        $foreColorValue,
        [System.Windows.Forms.TextFormatFlags]::Left `
            -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter `
            -bor [System.Windows.Forms.TextFormatFlags]::NoPadding `
            -bor [System.Windows.Forms.TextFormatFlags]::EndEllipsis
    )
}