using namespace System.Windows.Forms

<# CACHE #>
function Set-Cache  { param( [string]$Key, $Value ) Set-GlobalCache -Key "PowerForm.$Key" -Value $Value }
function Get-Cache  { param( [string]$Key ) return Get-GlobalCache -Key "PowerForm.$Key" }
function Test-Cache { param( [string]$Key, $Value ) Test-GlobalCache -Key "PowerForm.$Key" -Value $Value }


$script:FormConfig = @{
    Main = @{
        Properties  = @{
            Text        = "Energieoptionen"
            Icon        = "Power"
            ClientSize  = [Size]::new(420,370)
        }
        Controls    = @{
            Header = @{
                Control     = "Label"
                Text        = "Energieoptionen".ToUpper()
                Font        = Get-Font -Preset "Header"
                Dock        = "Top"
                Height     = 50
            }
            PowerTable = @{
                Control     = "TableLayoutPanel"
                Padding     = [Padding]::new(10)
                Column      = @("55", "25", "20")
                Row         = @( 30, 30, 30, 30, 30, 30, 30, 30, 40, "AutoSize" )
                Controls    = & {
                    $controls = [ordered]@{}
                    $Schemes = @{ AC = "Netzbetrieb"; DC = "Akkubetrieb" }
                    $Types   = @{ Standby = "Energiesparmodus"; Hibernate = "Ruhezustand"; Monitor = "Monitor ausschalten" }

                    foreach ($scheme in $Schemes.Keys) {
                        $controls["PowerLabel$scheme"] = @{
                            Control     = "Label"
                            Text        = $Schemes[$scheme]
                            ColumnSpan  = 3
                        }

                        foreach ($type in $Types.Keys) {
                            $controls["$type`Label$scheme"]  = @{ Control = "Label"; Text = $Types[$type] + ":"; TextAlign = "MiddleRight" }
                            $controls["$type`Value$scheme"]  = @{ Control = "Label" }
                            $controls["$type`Button$scheme"] = @{ 
                                Control = "Button"; 
                                Text    = "Ändern"; 
                                Tag     = @{ 
                                    scheme = $scheme; 
                                    type = $type; 
                                    groupboxtext = "$($Types[$type]) ($($Schemes[$scheme]))" } 
                            }
                        }
                    }
                    $controls["DisableSleep"] = @{
                        Control     = "Button"
                        Text        = "Energiesparmodus deaktivieren"
                        Visible     = $false
                        Height      = 25 
                        Width       = 200
                        ColumnSpan  = 3

                        Tag        = @{ schemes = $Schemes; types = $Types }
                        Add_Click = { 
                            foreach ($type in $this.Tag.types.Keys) {
                                foreach ($scheme in $this.Tag.schemes.Keys) {
                                    Set-PowerStatus -PowerScheme $scheme -PowerType $type -Minutes 0
                                    (Get-Control $this "$type`Value$scheme").Text = "Nie"
                                }
                            }
                            $this.Visible = $false
                        }
                    }

                    return $controls
                }
            }
        }
        Events = @{
            Load = { 
                $powerTable = $this.Controls["PowerTable"]
                $Schemes = @{ AC = "Netzbetrieb"; DC = "Akkubetrieb" }
                $Types   = @{ Standby = "Energiesparmodus"; Hibernate = "Ruhezustand"; Monitor = "Monitor ausschalten" }

                foreach ($scheme in $Schemes.Keys) {
                    $powerTable.Controls["PowerLabel$scheme"].Text = $Schemes[$scheme]

                    foreach ($type in $Types.Keys) {

                        # Überprüfen, ob der Status bereits im Cache vorhanden ist, um unnötige Abfragen zu vermeiden
                        Test-Cache -Key "$type$scheme" -Value (Get-PowerStatus -PowerScheme $scheme -PowerType $type)
                        $powerStatus    = Get-Cache -Key "$type$scheme"
                        $disableSleep   = Get-Control $this "DisableSleep"
                        
                        # Aktualisieren des Texts basierend auf dem Statuswert
                        $valueControl       = $powerTable.Controls["$type`Value$scheme"]
                        $valueControl.Tag   = @{ disableSleep = $disableSleep }
                        $valueControl.Text  = if ($powerStatus -eq 0) { "Nie" } else { "$powerStatus Minuten"; $disableSleep.Visible = $true }
                        $valueControl.Add_TextChanged({ $this.Tag.disableSleep.Visible = $this.Text -ne "Nie" })
                        
                        # Hinzufügen der Click-Events für die Ändern-Buttons
                        $buttonControl      = $powerTable.Controls["$type`Button$scheme"]
                        $buttonControl.Add_Click({
                            $Tag = @{
                                scheme = $this.Tag.scheme
                                type = $this.Tag.type
                                groupboxtext = $this.Tag.groupboxtext
                            }
                            Show-PowerDialog -PowerScheme $Tag.scheme -PowerType $Tag.type -GroupBoxText $Tag.groupboxtext
                            Update-PowerControl -Control $this -PowerScheme $Tag.scheme -PowerType $Tag.type
                        })
                    }
                }
            }
        }
    }
    Change = @{
        Properties = @{
            Text        = "Energieoptionen Ändern"
            ClientSize  = [Size]::new(280,60)
            MinimizeBox = $false
            MaximizeBox = $false
            KeyPreview  = $true
            FormBorderStyle = "FixedDialog"
            Padding     = [Padding]::new(5)
            BackColor   = Get-Color "Dark"
            Icon       = "Power"
        }
        Controls = [ordered]@{ 
            GroupBox = @{ 
                Control     = "GroupBox" 
                Controls    = [ordered]@{
                    UpdateTable = @{
                        Control     = "TableLayoutPanel"
                        Column      = @(50, "AutoSize", "40")
                        Row         = @(30)
                        Controls    = [ordered]@{
                            InputMinutes = @{
                                Control     = "NumericUpDown"
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
                                Text        = "Ändern"
                                Dock        = "Fill"
                                Add_Click   = {
                                    $minutes    = (Get-Control $this "InputMinutes").Value
                                    $scheme     = $this.Tag.PowerScheme
                                    $type       = $this.Tag.PowerType

                                    Set-PowerStatus -PowerScheme $scheme -PowerType $type -Minutes $minutes
                                    $this.FindForm().Close()
                                }
                            }
                        }
                    }
                } 
        } }
        Events = @{
            KeyDown = {
                # Bestätigt die Eingabe, wenn die Enter-Taste gedrückt wird, aber nur wenn der Fokus auf dem Minuten-Textfeld liegt
                if ($this.ActiveControl.Name -eq "InputMinutes") {
                    if ($_.KeyCode -eq [Keys]::Enter) {
                        (Get-Control $this "ChangeButton").PerformClick()
                    }
                }
            }
            Load = {
                (Get-Control $this "GroupBox").Text = Get-Cache -Key "GroupBoxText"
                (Get-Control $this "InputMinutes").Value = Get-Cache -Key "CurrentMinutes"
                (Get-Control $this "ChangeButton").Tag = @{
                    PowerScheme = Get-Cache -Key "PowerScheme"
                    PowerType   = Get-Cache -Key "PowerType"
                }
            }
            Shown = {
                $inputMinutes = Get-Control $this "InputMinutes"
                $null = $inputMinutes.Focus()
                $inputMinutes.Select(0, $inputMinutes.Text.Length)
            }
        }
    }
}

<# POWERSTATUS #>
function Get-PowerStatus {
    param ( [ValidateSet("AC", "DC")][string]$PowerScheme, [ValidateSet("Standby", "Hibernate", "Monitor")][string]$PowerType )

    # Abrufen des aktuellen Power-Status mit powercfg    
    $subgroup       = @{ Standby = "SUB_SLEEP";   Hibernate = "SUB_SLEEP";     Monitor = "SUB_VIDEO" }[$PowerType]
    $setting        = @{ Standby = "STANDBYIDLE"; Hibernate = "HIBERNATEIDLE"; Monitor = "VIDEOIDLE" }[$PowerType]
    $PowerStatus    = powercfg /query SCHEME_CURRENT $subgroup $setting
    
    
    $schemeString   = @{ AC = "Wechselstrom"; DC = "Gleichstrom" }[$PowerScheme]
    
    # Extrahieren der Sekunden aus der Ausgabe von powercfg
    $value      = ($PowerStatus | Select-String $schemeString).ToString().Split(":")[-1].Trim()
    $seconds    = [convert]::ToInt32($value, 16)
    $minutes    = if ($seconds -eq 0) { 0 } else { $seconds / 60 }

    # Rückgabe der Minuten als Ganzzahl
    return [int]$minutes
}
function Set-PowerStatus {
    param ( [ValidateSet("AC", "DC")][string]$PowerScheme, [ValidateSet("Standby", "Hibernate", "Monitor")][string]$PowerType, [int]$Minutes )

    # Validierung der Minutenanzahl
    if ($Minutes -lt 0) { throw "Ungültige Minutenanzahl. Bitte geben Sie eine positive Zahl ein."; return }
    
    # Festlegen des Power-Status mit powercfg
    $schemeCommand  = @{ AC = "/setacvalueindex"; DC = "/setdcvalueindex" }[$PowerScheme]
    $subgroup       = @{ Standby = "SUB_SLEEP";   Hibernate = "SUB_SLEEP";     Monitor = "SUB_VIDEO" }[$PowerType]
    $setting        = @{ Standby = "STANDBYIDLE"; Hibernate = "HIBERNATEIDLE"; Monitor = "VIDEOIDLE" }[$PowerType]
    $Seconds        = $Minutes * 60

    # Anwenden der Änderungen mit powercfg
    powercfg $schemeCommand SCHEME_CURRENT $subgroup $setting $Seconds
    powercfg /setactive SCHEME_CURRENT

    # Aktualisieren des Caches mit dem neuen Wert
    Set-Cache -Key "$PowerType$PowerScheme" -Value $Minutes
}

<# POWERDIALOG #>
function Show-PowerDialog {
    param ( [string]$PowerScheme, [string]$PowerType, [string]$GroupBoxText )
    Set-Cache -Key "GroupBoxText" -Value $GroupBoxText
    Set-Cache -Key "CurrentMinutes" -Value (Get-Cache -Key "$PowerType$PowerScheme")
    Set-Cache -Key "PowerScheme" -Value $PowerScheme
    Set-Cache -Key "PowerType" -Value $PowerType

    Start-Form $FormConfig.Change
}




<# POWERTAB #>
function Initialize-PowerTab {
    param ( [Parameter(Mandatory=$true)][System.Windows.Forms.TabPage]$powerTab )
    $powerTable     = $powerTab.Controls["PowerTable"]
    $disableSleep   = $powerTable.Controls["DisableSleep"]

    $schemes    = @{ AC = "Netzbetrieb"; DC = "Akkubetrieb" }
    $types      = @{ Standby = "Energiesparmodus"; Hibernate = "Ruhezustand"; Monitor = "Monitor ausschalten" }
    
    foreach ($scheme in $schemes.Keys) {
        $powerTable.Controls["PowerLabel$scheme"].Text = $schemes[$scheme]

        foreach ($type in $types.Keys) {
            # Überprüfen, ob der Status bereits im Cache vorhanden ist, um unnötige Abfragen zu vermeiden
            Test-Cache -Key "$type$scheme" -Value (Get-PowerStatus -PowerScheme $scheme -PowerType $type)
            $powerStatus    = Get-Cache -Key "$type$scheme"

            # Aktualisieren der Label- und Value-Controls basierend auf dem PowerType und PowerScheme
            $labelControl           = $powerTable.Controls["$type`Label$scheme"]
            $labelControl.Text      = $types[$type] + ":"
            $labelControl.TextAlign = "MiddleRight"
            
            # Aktualisieren des Texts basierend auf dem Statuswert
            $valueControl           = $powerTable.Controls["$type`Value$scheme"]
            $valueControl.Text      = if ($powerStatus -eq 0) { "Nie" } else { "$powerStatus Minuten"; $disableSleep.Visible = $true }
            $valueControl.Add_TextChanged({ (Get-Control $this "DisableSleep").Visible = $this.Text -ne "Nie" })

            # Hinzufügen der Click-Events für die Ändern-Buttons
            $buttonControl          = $powerTable.Controls["$type`Button$scheme"]
            $buttonControl.Text     = "Ändern"
            $buttonControl.Tag      = @{ scheme = $scheme; type = $type; powertab = $powerTab; groupboxtext = "$($types[$type]) ($($schemes[$scheme]))" }
            $buttonControl.Add_Click({ 
                Show-PowerDialog -PowerScheme $this.Tag.scheme -PowerType $this.Tag.type -GroupBoxText $this.Tag.groupboxtext
                Update-PowerTab -powerTab $this.Tag.powertab 
            })

        }
    }
    $disableSleep.Tag = $powerTab
    $disableSleep.Add_Click({ Update-PowerTab -powerTab $this.Tag -DisableSleepButton })
    
}
function Update-PowerTab {
    param ( [Parameter(Mandatory=$true)][System.Windows.Forms.TabPage]$powerTab, [switch]$DisableSleepButton )

    $powerTable = $powerTab.Controls["PowerTable"]
    foreach ($control in $powerTable.Controls) {
        if ($control.Name -match "^(Standby|Hibernate|Monitor)Value(AC|DC)$") {
            $type           = $matches[1]
            $scheme         = $matches[2]
            if ($DisableSleepButton) { Set-PowerStatus -PowerScheme $scheme -PowerType $type -Minutes 0; $powerStatus = 0 } 
            else { $powerStatus    = Get-PowerStatus -PowerScheme $scheme -PowerType $type }
            $control.Text   = if ($powerStatus -eq 0) { "Nie" } else { "$powerStatus Minuten" }
        }
        if ($control.Name -eq "DisableSleep") { $disableSleep = $control }
    }
    if ($DisableSleepButton) { $disableSleep.Visible = $false }
}


<# POWERFORM #>
function Get-PowerStatusConfig { return $FormConfig.Main }
function Show-PowerStatus { Start-Form $FormConfig.Main }
function Update-PowerControl {
    param( [Control]$Control, [string]$PowerScheme, [string]$PowerType )
    $powerStatus = Get-PowerStatus -PowerScheme $PowerScheme -PowerType $PowerType
    $valueControl = Get-Control $Control "$PowerType`Value$PowerScheme"
    $valueControl.Text = if ($powerStatus -eq 0) { "Nie" } else { "$powerStatus Minuten" }
}