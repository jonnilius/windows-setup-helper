function Show-Window {
    param ( [Parameter(Mandatory = $true)]$Control )

    $Form = if ($Control -ne [System.Windows.Forms.Form]) { $Control.FindForm() } else { $Control }
    if (-not $Form.Visible) { $Form.Visible = $true }
}
function Hide-Window {
    param ( [Parameter(Mandatory = $true)]$Control )

    $Form = if ($Control -ne [System.Windows.Forms.Form]) { $Control.FindForm() } else { $Control }
    if ($Form.Visible) { $Form.Visible = $false }
}