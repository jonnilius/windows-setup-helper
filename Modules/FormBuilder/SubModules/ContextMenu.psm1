using namespace System.Windows.Forms


function New-ContextMenu {
    param( [hashtable]$Config = @{}, [System.Windows.Forms.Control]$SourceControl = $null )
    $contextMenu = [ContextMenuStrip]::new()

    # Setze einige Standardwerte für das Kontextmenü
    $contextMenu.ForeColor = Get-Color "Accent"
    $contextMenu.ShowImageMargin = $true

    # Wenn eine SourceControl angegeben ist, weise sie dem Kontextmenü zu und füge ein Opening-Event hinzu
    if ($SourceControl) { 
        $contextMenu.SourceControl = $SourceControl 
        $contextMenu.Add_Opening({
            param($src, $e)
            $sourceControl  = $src.SourceControl
            $controlName    = $sourceControl.GetType().Name
            switch ($controlName) {
                "ListView"  { $e.Cancel = $sourceControl.SelectedItems.Count -eq 0 }
                default     { $e.Cancel = $false } # Für andere Steuerelemente immer öffnen
            }
            
        })
    }

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