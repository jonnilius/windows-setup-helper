<# TWEAKS #>
$WindowsDefenderTweaks = [ordered]@{
        DisableWindowsDefender      = @{ 
            Text        = 'Windows Defender deaktivieren';
            Registry    = @{
                RegistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
                ValueName = 'DisableAntiSpyware'
                ValueType = 'Dword'
                ValueData = 1 
            }
        }
        DisableSmartScreen          = @{ 
            Text        = 'SmartScreen deaktivieren'
            Registry    = @{
                RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'               
                ValueName = 'SmartScreenEnabled'
                ValueType = 'String'
                ValueData = 'Off' 

            }
        }
        DisableRealTimeProtection   = @{ 
            Text        = 'Echtzeitschutz deaktivieren'
            Registry    = @{
                RegistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection'
                ValueName = 'DisableRealtimeMonitoring'
                ValueType = 'Dword'
                ValueData = 1 

            }
        }
        DisableCloudProtection      = @{ 
            Text        = 'Cloud-Schutz deaktivieren'
            Registry    = @{
                RegistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet'
                ValueName = 'DisableBlockAtFirstSeen'
                ValueType = 'Dword'
                ValueData = 1 

            }
        }
    }
$ScriptTweaks = [ordered]@{
    HideStartMenuIcons      = @{ Name = 'Startmenü-Icons entfernen';        Script = 'Remove-StartMenuIcons.ps1' }
    UninstallOneDrive       = @{ Name = 'OneDrive deinstallieren';          Script = 'Uninstall-OneDrive.ps1' }
    UninstallMicrosoftEdge  = @{ Name = 'Microsoft Edge deinstallieren';    Script = 'Uninstall-MicrosoftEdge.ps1' }
    ThemePatcher            = @{ Name = 'UltraUXThemePatcher';              Script = 'Start-ThemePatcher.ps1' }
}

<# TweakControls #>
function Add-TableLayoutPanel {
    param ( 
        # Title
        [string]$TitleKey, [string]$Title = "TemplateTable",
        # Spalten
        $Column = @( "AutoSize" )
    )

    # Wenn kein TitleKey angegeben ist, wird er aus dem Title generiert (Leerzeichen entfernt + "Title" angehängt)
    if (-not $TitleKey) { $TitleKey = ($Title -replace '\s', '') + "Title" }

    # Erstelle die TableLayoutPanel-Struktur
    $Table = New-TweakTable -Column $Column

    # Füge den Titel als Label hinzu
    $Label = New-TweakLabel -Text $Title
    $Label.ColumnSpan = $Column.Count
    $Table.Controls[$TitleKey] = $Label
    $Table.Row += 30

    return $Table
}
function New-TweakTable {
    param ( $Column = @( "AutoSize" ) )
    return @{
        Control     = "TableLayoutPanel"
        Column      = $Column
        Row         = @()
        Controls    = [ordered]@{}
    }
}
function New-TweakButton {
    param ( [string]$Text = "TweakButton", $Tag, [ScriptBlock]$Click )

    $tweakButton = @{
        Control     = "Button"
        Text        = $Text
        Dock        = "Fill"
        Add_Click   = $Click
    }
    if ($Tag) { $tweakButton.Tag = $Tag }

    return $tweakButton
}
function New-TweakLabel {
    param ( [string]$Text = "TweakLabel" )

    $tweakLabel = @{
        Control = "Label"
        Text    = $Text
        Dock    = "Fill"
    }

    # Platziere den Starttext in Tag.Text
    $tweakLabel.Tag = @{ Text = $Text }

    return $tweakLabel
}
function New-TweakCheckBox {
    param ( [switch]$Checked, [bool]$Enabled = $true )

    return @{
        Control     = "CheckBox"
        Dock        = "Fill"
        CheckAlign  = "MiddleCenter"
        Checked     = $Checked
        Enabled     = $Enabled
        # BackColor   = Get-Color "Debug1"
    }
}


<# Tweaks Tables #>
function Get-TestTweakTable {
    $TestTweakTable = Add-TableLayoutPanel -Title "Test Tweaks" -Column @("85", "15")

    foreach ($i in 1..5) {
        
        $TestTweakTable.Controls["TestLabel$i"]  = New-TweakLabel  -Text "Test Label $i"
        if ($i -eq 3){
            $testTweakTable.Controls["TestCheckbox$i"] = New-TweakCheckBox -Checked
        } else {
            $testTweakTable.Controls["TestCheckbox$i"] = New-TweakCheckBox
        }
            
        # $TestTweakTable.Controls["TestButton$i"] = New-TweakButton -Text "Toggle" -Tag @{ active = $false; i = $i} -Click {
        #     $this.Tag.active = -not $this.Tag.active
            
        #     $label      = Get-TableCell ($this.Parent) (0,$this.Tag.i)
        #     $label.Text = $label.Tag.Text

        #     if ($this.Tag.active) { $label.Text += " (aktiv)" }
        # }



        $TestTweakTable.Row += 40
    }
    $TestTweakTable.Row += "AutoSize"

    return $TestTweakTable
}

function Get-ScriptTweaksTable {
    param ( [string]$ScriptRoot )
    if (-not $ScriptRoot -or -not (Test-Path $ScriptRoot)) { $ScriptRoot = Join-Path $PSScriptRoot "Scripts" }
    
    # Erstelle Tabelle
    $ScriptTweaksTable = Add-TableLayoutPanel -Title "Script Tweaks"
    foreach ($tweak in $ScriptTweaks.GetEnumerator()) {

        # Überprüfe, ob das Skript existiert, andernfalls überspringe den Button und gebe eine Warnung aus
        $Path = Join-Path $ScriptRoot $tweak.Value.Script
        if (-not (Test-Path $Path)) { 
            Write-Warning "Skript für '$($tweak.Value.Name)' nicht gefunden: $($tweak.Value.Script). Button wird übersprungen."
            continue 
        }

        # Erstelle Button und füge der Tabelle hinzu
        $ScriptTweaksTable.Controls[$tweak.Key] = New-TweakButton -Text $tweak.Value.Name -Tag $Path -Click { & $this.Tag }
        $ScriptTweaksTable.Row += 40
    }
    $ScriptTweaksTable.Row += "AutoSize" # Abschlusszeile
    
    return $ScriptTweaksTable
}
function Get-WindowsDefenderTable {
    param ( [switch]$WhatIf )
    $Tweaks = $WindowsDefenderTweaks
    
    # Erstelle Tabelle
    $Table = Add-TableLayoutPanel -Title "Windows Defender" -Column ( "100", 30 )
    foreach ($tweak in $Tweaks.GetEnumerator()) {
        # Label erstellen und hinzufügen
        $LabelKey   = $tweak.Key + "Label"
        $LabelText  = $tweak.Value.Text
        $Label      = New-TweakLabel -Text $LabelText
        $Label.TextAlign = "MiddleCenter"
        $Table.Controls[$LabelKey] = $Label

        # Prüfe vorhandenen Registry-Eintrag
        $params     = $tweak.Value.Registry
        $ValueExist = Test-RegistryValue @params
        
        # CheckBox erstellen und hinzufügen
        $Table.Controls[$tweak.Key + "CheckBox"] = New-TweakCheckBox -Checked:$ValueExist

        $Table.Row += 40 # Spaltengröße hinzufügen
    }
    $Table.Row += "AutoSize" # Abschlussspalte

    # Return
    return $Table
}
<# Export TweaksTab #>
$TabConfig = @{
    Control     = "TabPage"
    Text        = "Tweaks"
    Padding     = [Padding]::new(0)
    Tag         = @{ Header = "WINDOWS TWEAKS"; Size = [Size]::new(600,400) }
    Controls    = [ordered]@{
        TweaksTable = @{
            Control     = "TableLayoutPanel"
            Padding     = [Padding]::new(0)
            Column      = @("50", "50")
            Controls    = [ordered]@{
                # TestTweaks              = Get-TestTweakTable
                ScriptTweaks            = Get-ScriptTweaksTable
                WindowsDefenderTable    = Get-WindowsDefenderTable
            }
        }
    }
}
function Add-TweaksTab {
    param ( [Parameter(Mandatory)][System.Windows.Forms.TabControl]$TabControl )

    $tweaksTab = New-Control $TabConfig

    $TabControl.TabPages.Add($tweaksTab)
}
