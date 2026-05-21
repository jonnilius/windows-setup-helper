using namespace System.Windows.Forms

<# POWERSTATUS (Funktionen) #>
function Get-PowerStatus {
    param ( 
        [ValidateSet("AC", "DC")][string]$PowerScheme, 
        [ValidateSet("Standby", "Hibernate", "Monitor")][string]$PowerType 
    )

    $schemeString   = @{ AC = "Wechselstrom"; DC = "Gleichstrom" }[$PowerScheme]
    $subgroup       = @{ Standby = "SUB_SLEEP";   Hibernate = "SUB_SLEEP";     Monitor = "SUB_VIDEO" }[$PowerType]
    $setting        = @{ Standby = "STANDBYIDLE"; Hibernate = "HIBERNATEIDLE"; Monitor = "VIDEOIDLE" }[$PowerType]
    
    # Abrufen des aktuellen Power-Status mit powercfg    
    $PowerStatus    = powercfg /query SCHEME_CURRENT $subgroup $setting
    
    # Extrahieren der Sekunden aus der Ausgabe von powercfg
    $value      = ($PowerStatus | Select-String $schemeString).ToString().Split(":")[-1].Trim()
    $seconds    = [convert]::ToInt32($value, 16)
    $minutes    = if ($seconds -eq 0) { 0 } else { $seconds / 60 }

    # Rückgabe der Minuten als Ganzzahl
    return [int]$minutes
}
function Set-PowerStatus {
    param ( 
        [ValidateSet("AC", "DC")][string]$PowerScheme, 
        [ValidateSet("Standby", "Hibernate", "Monitor")][string]$PowerType, 
        [int]$Minutes 
    )

    # Validierung der Minutenanzahl
    if ($Minutes -lt 0) { Write-Warning "Ungültige Minutenanzahl. Bitte geben Sie eine positive Zahl ein."; return }
    
    # Festlegen des Power-Status mit powercfg
    $schemeCommand  = @{ AC = "/setacvalueindex"; DC = "/setdcvalueindex" }[$PowerScheme]
    $subgroup       = @{ Standby = "SUB_SLEEP";   Hibernate = "SUB_SLEEP";     Monitor = "SUB_VIDEO" }[$PowerType]
    $setting        = @{ Standby = "STANDBYIDLE"; Hibernate = "HIBERNATEIDLE"; Monitor = "VIDEOIDLE" }[$PowerType]
    $Seconds        = $Minutes * 60

    # Anwenden der Änderungen mit powercfg
    powercfg $schemeCommand SCHEME_CURRENT $subgroup $setting $Seconds
    powercfg /setactive SCHEME_CURRENT
}


<# POWERTABLE (Content) #>
function Get-PowerTable {
    return @{
    Control     = "TableLayoutPanel"
    Padding     = [Padding]::new(10)
    Column      = @( "55", "25", "20" )
    Row         = @( 30, 30, 30, 30, 30, 30, 30, 30, 40, "AutoSize" )
    Controls    = & {
            # Dynamische Erstellung der Controls für die Energieoptionen
            $Types      = @{ Standby = "Energiesparmodus"; Hibernate = "Ruhezustand"; Monitor = "Monitor ausschalten" }
            $Schemes    = @{ AC = "Netzbetrieb"; DC = "Akkubetrieb" }
            $controls   = [ordered]@{}

            foreach ($scheme in $Schemes.Keys) {
                # Titel-Label für jeden Energieschema
                $controls["PowerLabel$scheme"] = @{ Control = "Label"; ColumnSpan = 3; Text = $Schemes[$scheme] }

                foreach ($type in $types.Keys) {
                    $PowerStatus = Get-PowerStatus -PowerScheme $scheme -PowerType $type
                    $controls["$Type`Label$scheme"]   = @{ Control = "Label"; Text = $Types[$type] + ":"; TextAlign = "MiddleRight" }
                    $controls["$Type`Value$scheme"]   = @{ Control = "Label"; Text = $PowerStatus }
                    $controls["$Type`Button$scheme"]  = @{ 
                        Control = "Button"; 
                        Text = "Ändern"; 
                        Tag = @{ type = $type; scheme = $scheme } 
                        Add_CLick = {
                            Show-PowerDialog -PowerScheme $this.Tag.scheme -PowerType $this.Tag.type
                            Update-PowerTable ($this.Parent)
                        }
                    }
                }
            }
            # Button zum Deaktivieren des Energiesparmodus
            $controls["DisableSleep"] = @{
                Control     = "Button"
                Text        = "Energiesparmodus deaktivieren"
                Visible     = $false
                Size       = [Size]::new(225,25)
                ColumnSpan  = 3
                Add_Click   = { Clear-PowerTable ($this.Parent) }
            }

            return $controls
        }
    } 
}
function Clear-PowerTable {
    param ( $container)

    $powerTable = $container
    foreach ($control in $powerTable.Controls) {
        if ($control.Name -match "^(Standby|Hibernate|Monitor)Value(AC|DC)$") {
            $type           = $matches[1]
            $scheme         = $matches[2]
            Set-PowerStatus -PowerScheme $scheme -PowerType $type -Minutes 0
            
            $control.Text   = "Nie"
        }
    }
    $powerTable.Controls["DisableSleep"].Visible = $false
}
function Update-PowerTable {
    param ( $powerTable )

    $Minutes = 0
    foreach ($control in $powerTable.Controls) {
        if ($control.Name -match "^(Standby|Hibernate|Monitor)Value(AC|DC)$") {
            $type           = $matches[1]
            $scheme         = $matches[2]
            $PowerStatus = Get-PowerStatus -PowerScheme $scheme -PowerType $type
            $Minutes += $PowerStatus
            $control.Text = if ($PowerStatus -eq 0){ "Nie" } else { "$PowerStatus Minuten" }
        }
    }
    $powerTable.Controls["DisableSleep"].Visible = $Minutes -gt 0
}



function Get-PowerConfig {
    param( [switch]$TabPage, [switch]$Form )
    if ($TabPage -eq $Form){ Write-Warning "[Get-PowerConfig] Mindestens einen Parameter setzen!"}

    $Config = @{
        $TabPage = @{
                Control     = "TabPage"
                Tag         = @{ Header = "ENERGIEOPTIONEN"; Size = [Size]::new(440,410); Expand = { Show-PowerForm } }
                Add_Enter   = { Update-PowerTable $this.Controls["PowerTable"] }
            }
        $Form = @{
                Properties  = @{
                    Icon        = "Power"
                    ClientSize  = [Size]::new(420,370)
                }
                Controls = @{
                    Header = @{
                        Control     = "Label"
                        Text        = "Energieoptionen".ToUpper()
                        Font        = Get-Font -Preset "Header"
                        Dock        = "Top"
                        Height     = 50
                    }
                }
                Events = @{
                    Load = { Update-PowerTable $this.Controls["PowerTable"] }
                }

            }
    }[$true]
    $Config += @{
        Text        = "Energieoptionen"
    }
    $Config.Controls += @{ PowerTable = Get-PowerTable }

    return $Config
}


<# SHOW FORMS #>
function Show-PowerDialog {
    param ( [string]$PowerScheme, [string]$PowerType )
    $Type      = @{ Standby = "Energiesparmodus"; Hibernate = "Ruhezustand"; Monitor = "Monitor ausschalten" }[$PowerType]
    $Scheme    = @{ AC = "Netzbetrieb"; DC = "Akkubetrieb" }[$PowerScheme]

    $Properties = @{
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
    $Controls   = [ordered]@{ 
        GroupBox = @{ 
            Control     = "GroupBox" 
            Text        = "$Type ($Scheme)"
            Controls    = [ordered]@{
                UpdateTable = @{
                    Control     = "TableLayoutPanel"
                    Column      = @(50, "AutoSize", "40")
                    Row         = @(30)
                    Controls    = [ordered]@{
                        InputMinutes = @{
                            Control     = "NumericUpDown"
                            Value       = Get-PowerStatus -PowerScheme $PowerScheme -PowerType $PowerType
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
                            # Tag         = {}
                            Add_Click   = {
                                $form       = $this.FindForm()
                                $minutes    = (Get-Control $this "InputMinutes").Value
                                # $scheme     = $form.Tag["PowerScheme"]
                                # $type       = $form.Tag["PowerType"]

                                Set-PowerStatus -PowerScheme $PowerScheme -PowerType $PowerType -Minutes $minutes
                                $form.Close()
                            }.GetNewClosure()
                        }
                    }
                }
            } 
        } 
    }
    $Events     = @{
        KeyDown = {
            # Bestätigt die Eingabe, wenn die Enter-Taste gedrückt wird, aber nur wenn der Fokus auf dem Minuten-Textfeld liegt
            if ($this.ActiveControl.Name -eq "InputMinutes") {
                if ($_.KeyCode -eq [Keys]::Enter) {
                    (Get-Control $this "ChangeButton").PerformClick()
                }
            }
        }
        Shown = {
            $inputMinutes = Get-Control $this "InputMinutes"
            $null = $inputMinutes.Focus()
            $inputMinutes.Select(0, $inputMinutes.Text.Length)
        }
    }


    Start-Form @{ 
        Properties  = $Properties
        Controls    = $Controls
        Events      = $Events 
    } | Out-Null

    return Get-PowerStatus -PowerScheme $PowerScheme -PowerType $PowerType
}
function Show-PowerForm {
    $FormConfig = Get-PowerConfig -Form
    Start-Form $FormConfig
}

<# EXPORT POWERSTATUS #>
function Get-PowerStatusTab { return (New-Control (Get-PowerConfig -TabPage) "PowerTab") }
