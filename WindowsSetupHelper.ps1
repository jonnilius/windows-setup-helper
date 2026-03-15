using namespace System.Windows.Forms
using namespace System.Drawing
using namespace Console
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization
[System.Windows.Forms.Application]::EnableVisualStyles()


# Überprüfen, ob das Skript mit Administratorrechten ausgeführt wird
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')){
    Write-Host "Starte als Administrator neu..."
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    [System.Environment]::Exit(0)
}

$global:AppInfo = @{
    Name       = "Windows Setup Helper"
    Version    = "0.9.7"
    Author     = "jonnilius"
    Company    = "BORINAS"
    License    = "MIT License"
}
$global:Colors = @{
    Accent     = "#C0393B"
    Dark       = "#2D3436"
    White      = "#EEEEEE"
}
$global:toolTip = & {
    $toolTip = New-Object System.Windows.Forms.ToolTip
    $toolTip.BackColor = [ColorTranslator]::FromHtml($Colors.Dark)
    $toolTip.ForeColor = [ColorTranslator]::FromHtml($Colors.White)
    $toolTip.AutoPopDelay = 5000
    $toolTip.InitialDelay = 500
    $toolTip.ReshowDelay = 500
    return $toolTip
}

# $ErrorActionPreference = "SilentlyContinue"

$env:PSModulePath += ";$PSScriptRoot\Modules"
Import-Module "$PSScriptRoot\Modules\Utils.psm1"
Import-Module "$PSScriptRoot\Modules\Forms.psm1"
Import-Module "$PSScriptRoot\Modules\Chocolatey.psm1"


$script:ChocoSetupList = Read-Chocolatey -SetupList




# global-Variablen
$global:restartScript = $false
# $global:LabelToolTip = [ToolTip]::new() # Tooltip für Labels


<# FORM-DATA ############################################################################>
$FormConfig = @{
    Form = @{
        # Beim Hinzufügen von Events bezieht sich $this auf das jeweilige Form-Objekt
        Main = @{
            Text        = "$($AppInfo.Name) $($AppInfo.Version)"
            Icon        = Get-Icon "Main"
            ClientSize  = [Size]::new(400,565)
        }
        Chocolatey = @{
            Text        = "$($AppInfo.Name) - Chocolatey"
            Icon        = Get-Icon "Chocolatey"
            ClientSize  = [Size]::new(600,300)
        }
        About = @{
            Text        = "About $($AppInfo.Name)"
            Icon        = Get-Icon "About"
            ClientSize        = [Size]::new(350,400)
            FormBorderStyle = "FixedDialog"
            KeyPreview   = $true
            Add_KeyDown = { if ($_.KeyCode -eq "Escape") { $this.Close() } }
        }
        Debloat = @{
            Text        = "Tweaks & Debloat"
            Icon            = Get-Icon "Debloat"
            ClientSize      = [Size]::new(245,125)
            FormBorderStyle = "FixedDialog"
        }
        DeviceName = @{
            Text        = "Gerätename festlegen"
            Icon        = Get-Icon "DeviceName"
            ClientSize        = [Size]::new(300,60)
            Padding = [Padding]::new(5)
            FormBorderStyle = "FixedDialog"
        }
    }
    Button = @{
        ChocoListInstall = @{
            Text = "INSTALLIEREN"
            Font = [Font]::new("Consolas", 8)
            Dock = "Bottom"
        }
        ChocoListMore = @{
            Text = ("Chocolatey verwalten").ToUpper()
            Font = [Font]::new("Consolas", 8)
            Dock = "Bottom"
        }
        UninstallChoco = @{ 
            Text = "Chocolatey entfernen"
            Size = [Size]::new(190,25)
            Location = [Point]::new(10,35)
            Font = [Font]::new("Consolas", 8, [FontStyle]::Bold)
            Dock = "Bottom"
            BackColor = [ColorTranslator]::FromHtml("#2D3436")
            ForeColor = [ColorTranslator]::FromHtml("#C0393B")
            Add_Click = { 
                $confirm = [System.Windows.Forms.MessageBox]::Show("Möchten Sie Chocolatey wirklich entfernen?", "Bestätigung", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
                if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) { return }
                
                # $Form.Cursor = [Cursors]::AppStarting
                
                Start-Sleep -Seconds 1
                Uninstall-Chocolatey | Out-Null
                # $Main.Cursor = [Cursors]::Default
                Start-Sleep -Seconds 1
                [System.Windows.Forms.MessageBox]::Show("Chocolatey wurde erfolgreich entfernt.", "Erfolg", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
             }
        }
    }
    Label = @{
        ChocoListLabel = @{
            Text = "Wählen Sie die Programme aus, die Sie installieren möchten:"
            Font = [Font]::new("Consolas", 9, [FontStyle]::Italic)
            Dock = "Top"
            AutoSize = $false
            TextAlign = "MiddleCenter"
        }
        PackageLabel = @{
            Text = "INSTALLIERT"
            ForeColor = [ColorTranslator]::FromHtml("#EEEEEE")
            AutoSize = $true
            Location = [Point]::new(10,10)
            Font = [Font]::new("Consolas", 13, ([FontStyle]::Bold -bor [FontStyle]::Underline))
        }
    }
    Panel = @{
        DeviceName = @{
            Padding = [Padding]::new(10)
        }
        Debloat = @{
            Padding = [Padding]::new(10,5,10,5)
        }
    }
    ## Debug-Formular-Konfigurationen (für Entwicklung und Tests)
    Main = @{
        Properties = @{
            Text        = "$($AppInfo.Name) $($AppInfo.Version)"
            ClientSize  = [Size]::new(400,300) # Breite, Höhe
            Icon        = Get-Icon "Main"
        }
        Controls = @{
            Content = @{
                Control     = "FlowLayoutPanel"
                Padding     = [Padding]::new(10)
                Dock       = "Fill"
                ForeColor   = [ColorTranslator]::FromHtml($Colors.Accent)
                Controls    = [ordered]@{
                    ProcessBox = @{
                        Control = "Label"
                        Name = "ProcessBox"
                        Dock = "Top"
                        Height = 35
                        AutoSize = $false
                        Margin = [Padding]::new(0,0,0,10)
                        Font = [Font]::new("Consolas", 10, [FontStyle]::Italic)
                        BackColor = [ColorTranslator]::FromHtml($Colors.Accent)
                        ForeColor = [ColorTranslator]::FromHtml($Colors.White)
                        Visible = $false
                    }
                    ChangeDeviceNameButton = @{
                        Control = "Button"
                        Text = "Gerätename festlegen"
                        Font = [Font]::new("Consolas", 10)
                        Dock = "Top"
                        Margin = [Padding]::new(0,0,0,10)
                        Add_Click = { DeviceNameForm $FormConfig }
                    }
                    HideStartMenuIconsButton = @{
                        Control = "Button"
                        Text = "Startmenü aufräumen"
                        Font = [Font]::new("Consolas", 10)
                        Dock = "Top"
                        Margin = [Padding]::new(0,0,0,10)
                        Add_Click = { Hide-StartMenuIcons $this.FindForm().Controls["Content"].Controls["ProcessBox"] }
                    }
                    ChocoButton = @{
                        Control = "Button"
                        Name = "MoreButton"
                        Margin = [Padding]::new(0,0,0,10)
                        Text = "Paket-Manager – Chocolatey"
                        Font = [Font]::new("Consolas", 10)
                        Add_Click = { Start-Chocolatey }
                    }
                }
            }
            Header = @{
                Control = "Panel"
                Height = 50
                Dock = "Top"
                BackColor = [ColorTranslator]::FromHtml("#C0393B")
                Controls = @{
                    Label = @{
                        Control = "Label"
                        Text = "WINDOWS SETUP HELPER"
                        ForeColor = [ColorTranslator]::FromHtml("#2D3436")
                        BackColor = [ColorTranslator]::FromHtml("#C0393B")
                        Font = [Font]::new("Consolas", 24, [FontStyle]::Bold)
                        Dock = "Fill"
                        TextAlign = "MiddleCenter"
                        Add_DoubleClick = {
                            # Neustart des Skripts
                            $global:restartScript = $true
                            $this.FindForm().Close()
                        }
                    }
                }
            }
            Footer = @{
                Control = "Panel"
                Height = 15
                Dock = "Bottom"
                BackColor = [ColorTranslator]::FromHtml("#C0393B")
                Controls = @{
                    About = @{
                        Control = "Label"
                        Text = "About".ToUpper()
                        Font = [Font]::new("Consolas", 8, [FontStyle]::Underline)
                        BackColor = [ColorTranslator]::FromHtml("#C0393B")
                        ForeColor = [ColorTranslator]::FromHtml("#2D3436")
                        Location = [Point]::New(5,3)
                        Cursor = [Cursors]::Hand
                        ToolTip = "Informationen über das Skript"
                        Add_Click = { AboutForm $FormConfig }
                    }
                    Version = @{
                        Control = "Label"
                        Text = "Version $($AppInfo.Version)"
                        Font = [Font]::new("Consolas", 8, [FontStyle]::Italic)
                        BackColor = [ColorTranslator]::FromHtml("#C0393B")
                        ForeColor = [ColorTranslator]::FromHtml("#2D3436")
                        Location = [Point]::New(150,3)
                    }
                    Debloat = @{
                        Control = "Label"
                        Text = "DEBLOAT"
                        Font = [Font]::new("Consolas", 8, [FontStyle]::Underline)
                        BackColor = [ColorTranslator]::FromHtml("#C0393B")
                        ForeColor = [ColorTranslator]::FromHtml("#2D3436")
                        Location = [Point]::New(330,3)
                        Cursor = [Cursors]::Hand
                        ToolTip = "Mehr Optionen"
                        Add_Click = { DebloatForm $FormConfig }
                     }
                }
            }
        }
        Events = @{
            Load = { 
                $Content = $this.Controls["Content"] 
                $contentWidth = $Content.ClientSize.Width - $Content.Padding.Left - $Content.Padding.Right
                foreach ($control in $Content.Controls.Values) {
                    if ($control.Dock -eq "Top" -or $control.Dock -eq "Bottom") {
                        $control.Width = $contentWidth
                    }
                }
                $Content.Controls["ChocoButton"].Width = $contentWidth
            }
            Shown = { $this.Activate() }
            FormClosed = { [System.Environment]::Exit(0) }
        }
            
    }
}

function AboutForm {
    $Config = @{
        Properties = @{
            Text = "About - $($AppInfo.Name)"
            ClientSize = [Size]::new(350,400)
            Icon = Get-Icon "About"
            FormBorderStyle = "FixedDialog"
            KeyPreview = $true
        }
        Controls = @{
            Panel = @{
                Control = "Panel"
                Padding = [Padding]::new(10)
                Controls = @{
                    FlowPanel = @{
                        Control = "FlowLayoutPanel"
                        WrapContents = $false
                        Dock = "Fill"
                        Controls = [ordered]@{
                            Label = @{
                                Control = "Label"
                                Text = "WINDOWS SETUP HELPER"
                                ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
                                Dock = "Fill"
                                TextAlign = "MiddleCenter"
                                Margin = [Padding]::new(0,10,0,10)
                                Font = [Font]::new("Consolas", 20 )
                            }
                            RichText = @{
                                Control = "RichTextBox"
                                Size    = [Size]::new(310,310)
                                Text    = @"
Windows Setup Helper ist ein PowerShell-Skript, das die Einrichtung und Grundkonfiguration eines Windows-Systems deutlich vereinfacht.`n
Mit einer übersichtlichen grafischen Oberfläche ermöglicht es die schnelle Installation und Verwaltung von Programmen über Chocolatey, das Ändern von Systemeinstellungen wie Gerätename oder Zeitserver sowie das Anzeigen wichtiger Systeminformationen.`n
Das Skript richtet sich an alle, die Windows-PCs effizient und wiederholbar einrichten möchten - egal ob für den privaten Gebrauch, im Unternehmen oder in Bildungseinrichtungen.`n
Durch die Integration von Automatisierung und Benutzerfreundlichkeit spart der Windows Setup Helper Zeit und reduziert Fehlerquellen bei der Systemeinrichtung.`n
Version: $($AppInfo.Version)
Entwickler: $($AppInfo.Author)
Lizenz: MIT
"@
                            }
                        }
                    }
                }
            }
        }
        Events = @{
            KeyDown = { if ($_.KeyCode -eq "Escape") { $this.Close() } }
        }
    }
    $Form  = New-Form $Config
    $Form.ShowDialog()
    $Form.Dispose()
}
function DebloatForm {
    $Config = @{
        Properties = @{
            Text = "Tweaks & Debloat"
            ClientSize = [Size]::new(245,125)
            Icon = Get-Icon "Debloat"
            FormBorderStyle = "FixedDialog"
        }
        Controls = @{
            TableLayout = @{
                Control = "TableLayoutPanel"
                Dock = "Fill"
                Padding = [Padding]::new(0)
                BackColor = [ColorTranslator]::FromHtml($Colors.Dark)
                ColumnCount = 1
                RowCount = 3
                ColumnStyles = @(
                    [System.Windows.Forms.ColumnStyle]::new("Percent", 100)
                )
                RowStyles = @(
                    [System.Windows.Forms.RowStyle]::new("Percent", 33),
                    [System.Windows.Forms.RowStyle]::new("Percent", 33),
                    [System.Windows.Forms.RowStyle]::new("Percent", 34)
                )
                Controls = @{
                    UninstallOneDriveButton = @{
                        Control = "Button"
                        Text = "OneDrive entfernen"
                        Font = [Font]::new("Consolas", 8, [FontStyle]::Bold)
                        Dock = "Fill"
                        Add_Click = { Uninstall-OneDrive $this.Controls["Content"].Controls["ProcessBox"] }
                    }
                    UnpinStartMenuButton = @{
                        Control = "Button"
                        Text = "Startmenü aufräumen"
                        Font = [Font]::new("Consolas", 8, [FontStyle]::Bold)
                        Dock = "Fill"
                        Add_Click = { Unpin-StartMenu $this.Controls["Content"].Controls["ProcessBox"] }
                    }
                    ChangeDeviceNameButton = @{
                        Control = "Button"
                        Text = "Gerätename festlegen"
                        Font = [Font]::new("Consolas", 8, [FontStyle]::Bold)
                        Dock = "Fill"
                        Add_Click = { DeviceNameForm $FormConfig }
                     }
                }
            }
        }
    }
    $Form = New-Form $Config
    $Form.ShowDialog()
}
function DeviceNameForm {    
    $Config = @{
        Properties = @{
            Text = "Neuer Gerätename"
            ClientSize  = [Size]::new(300,40)
            Padding     = [Padding]::new(5)
            FormBorderStyle = "FixedDialog"
            Icon = Get-Icon "DeviceName"
        }
        Controls = @{
            TableLayout = @{
                Control = "TableLayoutPanel"
                Dock = "Fill"
                Padding = [Padding]::new(0)
                ColumnCount = 2
                RowCount = 1
                ColumnStyles = @(
                    [System.Windows.Forms.ColumnStyle]::new("Percent", 100),
                    [System.Windows.Forms.ColumnStyle]::new("AutoSize")
                )
                RowStyles = @(
                    [System.Windows.Forms.RowStyle]::new("Percent", 100)
                )
                Controls = @{
                    TextBox = @{
                        Control = "TextBox"
                        Font = [Font]::new("Consolas", 15)
                        # Width = 200
                        ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
                        BackColor = [ColorTranslator]::FromHtml($Colors.Dark)
                        TextAlign = "Center"
                        BorderStyle = "None"
                        Text = $env:COMPUTERNAME
                        Multiline = $false
                    }
                    Button = @{
                        Control = "Button"
                        Text = "Ändern"
                        Size = [Size]::new(100,25)
                        FlatStyle = "Flat"
                        TextAlign = "MiddleCenter"
                        BackColor = [ColorTranslator]::FromHtml($Colors.Dark)
                        ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
                        Add_Click = { ChangeDeviceName -NewName $this.Controls["TextBox"].Text }
                    }
                }
            }
        }
        Events = @{
            Shown = { $this.Controls["Button"].Focus() }
        }
    }
    $Form = New-Form $Config
    $Form.ShowDialog()
}

$Form = New-Form $FormConfig.Main
$Form.ShowDialog()
$Form.Dispose()

# Start-Chocolatey


<# Skript-Neustart #>
if ($global:restartScript) { 
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    [System.Environment]::Exit(0)
 }

