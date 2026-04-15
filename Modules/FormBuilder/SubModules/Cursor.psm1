
using namespace System.Windows.Forms

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