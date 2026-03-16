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
            ClientSize  = [Size]::new(400,295) # Breite, Höhe
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
                        Control     = "RichTextBox"
                        Name        = "ProcessBox"
                        Dock        = "Fill"
                        Margin      = [Padding]::new(0,0,0,10)
                        FontStyle = [FontStyle]::Italic
                        ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
                        Text = "Windows Setup Helper"
                        Visible = $false
                        Add_VisibleChanged = {
                            $this.FindForm().ClientSize = if ($this.Visible) { [Size]::new(400,400) } else { [Size]::new(400,295) }
                        }
                    }
                    PaketManagerButton = @{
                        Control = "Button"
                        Name = "PaketManagerButton"
                        Text = "Paket-Manager"
                        Font = [Font]::new("Consolas", 12)
                        
                        Margin = [Padding]::new(0,0,0,10)
                        Add_Click = {
                            $Content = $this.FindForm().Controls["Content"]
                            $PaketManager = $this.FindForm().Controls["PaketManager"]
                            $Content.Visible = $false
                            $PaketManager.Visible = $true
                        }
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
                    DebloatButton = @{
                        Control = "Button"
                        Text = "Debloater öffnen"
                        Font = [Font]::new("Consolas", 12)
                        Dock = "Top"
                        Margin = [Padding]::new(0,0,0,10)
                        Add_Click = { DebloatForm $FormConfig.Debloat }
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
                    Details = @{
                        Control = "Label"
                        Text = "DETAILS"
                        Font = [Font]::new("Consolas", 8, [FontStyle]::Underline)
                        BackColor = [ColorTranslator]::FromHtml("#C0393B")
                        ForeColor = [ColorTranslator]::FromHtml("#2D3436")
                        Location = [Point]::New(330,3)
                        Cursor = [Cursors]::Hand
                        ToolTip = "Mehr Optionen"
                        Add_Click = { 
                            $ProcessBox = $this.FindForm().Controls["Content"].Controls["ProcessBox"]
                            $ProcessBox.Visible = -not $ProcessBox.Visible
                         }
                     }
                }
            }
            PaketManager = @{
                Control = "FlowLayoutPanel"
                Padding = [Padding]::new(10)
                Dock = "Fill"
                visible = $false
                Controls = @{
                    WingetButton = @{
                        Control = "Button"
                        Name = "WingetButton"
                        Margin = [Padding]::new(0,0,0,10)
                        Text = "Winget"
                        Font = [Font]::new("Consolas", 12)
                        
                        Add_Click = { Start-Winget }
                        Add_VisibleChanged = {
                            if ($this.Visible) {
                                $this.Text = if (Get-Command -Name winget.exe -ErrorAction SilentlyContinue) { "Winget deinstallieren" } else { "Winget installieren" }
                            }
                        }
                    }
                    ChocoButton = @{
                        Control = "Button"
                        Name = "ChocoButton"
                        Margin = [Padding]::new(0,0,0,10)
                        Text = "Chocolatey"
                        Font = [Font]::new("Consolas", 12)
                        Add_Click = { Start-Chocolatey }
                    }
                    UninstallOneDriveButton = @{
                        Control = "Button"
                        Name = "UninstallOneDriveButton"
                        Text = "OneDrive entfernen"
                        Font = [Font]::new("Consolas", 12)
                        Dock = "Top"
                        Margin = [Padding]::new(0,0,0,10)
                        Add_Click = { Uninstall-OneDrive $this.FindForm().Controls["Content"].Controls["ProcessBox"] }
                    }
                }
            }
        }
        Events = @{
            Load = { 
                $Content        = $this.Controls["Content"]
                $PaketManager   = $this.Controls["PaketManager"]

                $contentWidth = $Content.ClientSize.Width - $Content.Padding.Left - $Content.Padding.Right
                foreach ($control in ($Content.Controls + $PaketManager.Controls)) {
                    if ($control -is [System.Windows.Forms.Button]) {
                        $control.Width = $contentWidth
                    }
                }
            }
            Shown = { $this.Activate() }
            FormClosed = { [System.Environment]::Exit(0) }
        }
            
    }
    Debloat = @{
        Properties  = @{
            Text = "Tweaks & Debloat"
            ClientSize = [Size]::new(400,150)
            Icon = Get-Icon "Debloat"
            FormBorderStyle = "FixedDialog"
        }
        Controls    = @{
            TableLayout = @{
                Control = "TableLayoutPanel"
                Dock = "Fill"
                Padding = [Padding]::new(0)
                ColumnCount = 1
                RowCount = 3
                ColumnStyles = @(
                    [System.Windows.Forms.ColumnStyle]::new("Percent", 100)
                )
                RowStyles = @(
                    [System.Windows.Forms.RowStyle]::new("Percent", 33),
                    [System.Windows.Forms.RowStyle]::new("Percent", 33),
                    [System.Windows.Forms.RowStyle]::new("Percent", 33)
                )
                Controls = @{
                    UninstallOneDrive = @{
                        Control = "Button"
                        Text = "OneDrive entfernen"
                        Font = [Font]::new("Consolas", 10)
                        Dock = "Fill"
                        Add_Click = { Uninstall-OneDrive $this.findForm().Controls["ProcessLabel"] }
                    }
                    UninstallEdge = @{
                        Control = "Button"
                        Text = "Microsoft Edge entfernen"
                        Font = [Font]::new("Consolas", 10)
                        Dock = "Fill"
                        Add_Click = { 
                            $processLabel = $this.FindForm().Controls["ProcessLabel"]
                            .\DebloatEdge.ps1 { param($msg) Update-StatusLabel -Label $processLabel -Message $msg } 
                            $processLabel.Visible = $false
                        }
                    }   
                    HideStartMenuIcons = @{
                        Control = "Button"
                        Text = "Startmenü aufräumen"
                        Font = [Font]::new("Consolas", 10)
                        Dock = "Fill"
                        Add_Click = { Hide-StartMenuIcons $this.FindForm().Controls["ProcessLabel"] }
                    }

                }
            }
            ProcessLabel = @{
                Control = "Label"
                Height  = 50
                Name    = "ProcessLabel"
                Font    = [Font]::new("Consolas", 10, [FontStyle]::Italic)
                Dock    = "Bottom"
                Width   = 400
                TextAlign = "MiddleCenter"
                Visible = $false
                Add_VisibleChanged = {
                    $this.FindForm().ClientSize = if ($this.Visible) { [Size]::new(400,200) } else { [Size]::new(400,125) }
                }

            }
        }
        Events      = @{
            Closed = { $this.Dispose() }
        }
    }
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

