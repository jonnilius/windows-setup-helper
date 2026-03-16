using namespace System.Windows.Forms
using namespace System.Drawing
using namespace Console
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization
[System.Windows.Forms.Application]::EnableVisualStyles()


# Überprüfen, ob das Skript mit Administratorrechten ausgeführt wird
if ( -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')){
    Write-Host "Starte als Administrator neu..."
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    [System.Environment]::Exit(0)
}

$global:AppInfo = @{
    Name        = "Windows Setup Helper"
    Version     = "0.9.8"
    Author      = "jonnilius"
    Company     = "BORINAS"
    License     = "MIT License"
    AdminRights = & {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}
$global:SystemInfo = @{
    ProductName     = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName
    DisplayVersion  = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
    CurrentBuild    = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
    
    OSVersion   = [System.Environment]::OSVersion.Version
    BuildNumber = [System.Environment]::OSVersion.Version.Build
    Is64Bit     = [System.Environment]::Is64BitOperatingSystem
    UserName    = [System.Environment]::UserName
    MachineName = [System.Environment]::MachineName
    SystemDrive = [System.Environment]::SystemDrive
    SystemRoot  = [System.Environment]::SystemRoot
    ProcessorCount = [System.Environment]::ProcessorCount
    CLRVersion  = [System.Environment]::Version.ToString()

    Architecture = if ([System.Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
}
$global:Colors = @{
    Accent     = "#C0393B"
    Dark       = "#2D3436"
    White      = "#EEEEEE"
    Debug1     = "#27AE60"
    Debug2     = "#2980B9"
}

# $ErrorActionPreference = "SilentlyContinue"

$env:PSModulePath += ";$PSScriptRoot\Modules"
Import-Module "$PSScriptRoot\Modules\Utils.psm1"
Import-Module "$PSScriptRoot\Modules\Forms.psm1"
Import-Module "$PSScriptRoot\Modules\Chocolatey.psm1"


$script:ChocoSetupList = Read-Chocolatey -SetupList
$DebloatList = @{
    "OneDrive" = @{
        Name = "OneDrive"
        Installed = Get-Command -Name "OneDrive.exe" -ErrorAction SilentlyContinue
        UninstallScript = { Test-Path .\Debloat\UninstallOneDrive.ps1 }
    }
    "Edge" = @{
        Name = "Microsoft Edge"
        Installed = Get-Package -Name "Microsoft Edge" -ErrorAction SilentlyContinue
        UninstallScript = { Test-Path .\Debloat\UninstallEdge.ps1 }
    }
    "StartMenu" = @{
        Name = "Startmenü-Icons"
        Installed = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -ErrorAction SilentlyContinue
        UninstallScript = { Test-Path .\Debloat\DebloatStartMenu.ps1 }
    }
}



$global:restartScript = $false


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
            Text        = $AppInfo.Name
            ClientSize  = [Size]::new(500,400) # Breite, Höhe
            Icon        = Get-Icon "Main"
            Padding     = [Padding]::new(10,10,10,0)
        }
        Controls = [ordered]@{
            MainPanel = @{
                Control     = "TableLayoutPanel"
                Dock       = "Fill"
                BackColor   = [ColorTranslator]::FromHtml($Colors.Dark)
                Row = @( "100", "AutoSize" )
                Controls    = [ordered]@{
                    InfoBox = @{
                        Control     = "Label"
                        Name        = "InfoBox"
                        Dock        = "Fill"
                        Margin      = [Padding]::new(10)
                        Font        = [Font]::new("Consolas", 10, [FontStyle]::Regular)
                        ForeColor   = [ColorTranslator]::FromHtml($Colors.Accent)
                        TextAlign   = "TopLeft"
                        Text        = ""
                    }
                    Buttons = @{
                        Control = "TableLayoutPanel"
                        Dock    = "Fill"
                        Margin  = [Padding]::new(5)
                        Column  = @( "50", "50" )
                        Row     = @( "50", "50" )
                        Controls = [ordered]@{
                            PaketManagerButton = @{
                                Control = "Button"
                                Name = "PaketManagerButton"
                                Text = "Paket-Manager"
                                Font = [Font]::new("Consolas", 12)
                                Margin = [Padding]::new(5)
                                Dock = "Fill"
                                Add_Click = {
                                    $mainPanel          = $this.FindForm().Controls["MainPanel"]
                                    $paketManagerPanel  = $this.FindForm().Controls["PaketManagerPanel"]

                                    $mainPanel.Visible = $false
                                    $paketManagerPanel.Visible = $true
                                }
                            }
                            DebloatButton = @{
                                Control = "Button"
                                Text = "Debloater"
                                Margin = [Padding]::new(5)
                                Font = [Font]::new("Consolas", 12)
                                Dock = "Fill"
                                Add_Click = { Start-Form $FormConfig.Debloat }
                            }
                            TweaksButton = @{
                                Control = "Button"
                                Text = "Tweaks"
                                Margin = [Padding]::new(5)
                                Font = [Font]::new("Consolas", 12)
                                Dock = "Fill"
                                Visible = $false
                                 # Add_Click = { Start-Form $FormConfig.Tweaks }
                            }
                            SettingsButton = @{
                                Control = "Button"
                                Text = "Einstellungen"
                                Margin = [Padding]::new(5)
                                Font = [Font]::new("Consolas", 12)
                                Dock = "Fill"
                            }
                        }
                    }
                }
            }
            PaketManagerPanel = @{
                Control = "TableLayoutPanel"
                Padding = [Padding]::new(10)
                BackColor = [ColorTranslator]::FromHtml($Colors.Dark)
                Dock = "Fill"
                visible = $false
                Controls = @{
                    Label = @{
                        Control = "Label"
                        Text = "Paket-Manager"
                        Font = [Font]::new("Consolas", 15, [FontStyle]::Bold)
                        ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
                        Dock = "Top"
                        TextAlign = "MiddleCenter"
                        Add_Click = {
                            $mainPanel = $this.FindForm().Controls["MainPanel"]
                            $paketManagerPanel = $this.FindForm().Controls["PaketManagerPanel"]
                            $paketManagerPanel.Visible = $false
                            $mainPanel.Visible = $true
                        }
                    }
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
                }
                Add_Click = {
                    $mainPanel = $this.FindForm().Controls["MainPanel"]
                    $paketManagerPanel = $this.FindForm().Controls["PaketManagerPanel"]
                    $paketManagerPanel.Visible = $false
                    $mainPanel.Visible = $true
                 }
            }
            DebloaterPanel = @{
                Control = "TableLayoutPanel"
                Padding = [Padding]::new(10)
                Dock = "Fill"
                visible = $false
                Controls = @{
                    Label = @{
                        Control = "Label"
                        Text = "Tweaks & Debloat"
                        Font = [Font]::new("Consolas", 15, [FontStyle]::Bold)
                        ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
                        Dock = "Top"
                        AutoSize = $false
                        TextAlign = "MiddleCenter"
                    }
                    OneDrivePanel = @{
                        Control = "Panel"
                        Name = "OneDrivePanel"
                        Dock = "Top"
                        AutoSize = $true
                        Controls = @{
                            OneDriveLabel = @{
                                Control = "Label"
                                Text = "OneDrive entfernen"
                                Font = [Font]::new("Consolas", 12)
                                ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
                                Dock = "Left"
                                AutoSize = $true
                            }
                            OneDriveStatus = @{
                                Control = "Label"
                                Name = "OneDriveStatus"
                                Text = if ($DebloatList["OneDrive"].Installed) { "INSTALLIERT" } else { "NICHT INSTALLIERT" }
                                Font = [Font]::new("Consolas", 10, [FontStyle]::Italic)
                                ForeColor = if ($DebloatList["OneDrive"].Installed) { [ColorTranslator]::FromHtml("#27AE60") } else { [ColorTranslator]::FromHtml("#C0393B") }
                                Dock = "Right"
                                AutoSize = $true
                            }
                            OneDriveButton = @{
                                Control = "Button"
                                Text = "Entfernen"
                                Font = [Font]::new("Consolas", 10)
                                Dock = "Bottom"
                                Add_Click = { Uninstall-OneDrive $this.FindForm().Controls["ProcessBox"] }
                            }
                        }
                    }
                }
                Add_Click = {
                    $mainPanel = $this.FindForm().Controls["MainPanel"]
                    $debloaterPanel = $this.FindForm().Controls["DebloaterPanel"]
                    $debloaterPanel.Visible = $false
                    $mainPanel.Visible = $true
                }
            }
            SettingsPanel = @{
                Control = "FlowLayoutPanel"
                Padding = [Padding]::new(10)
                Dock = "Fill"
                visible = $false
                Controls = @{
                    Label = @{
                        Control = "Label"
                        Text = "Einstellungen"
                        Font = [Font]::new("Consolas", 15, [FontStyle]::Bold)
                        ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
                        Dock = "Top"
                        AutoSize = $false
                        TextAlign = "MiddleCenter"
                    }
                }
                Add_Click = {
                    $mainPanel = $this.FindForm().Controls["MainPanel"]
                    $settingsPanel = $this.FindForm().Controls["SettingsPanel"]
                    $settingsPanel.Visible = $false
                    $mainPanel.Visible = $true
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
                Control = "TableLayoutPanel"
                Height = 30
                Column = @("AutoSize", "100", "AutoSize")
                Dock = "Bottom"
                ForeColor = [ColorTranslator]::FromHtml($Colors.Dark)
                BackColor = [ColorTranslator]::FromHtml($Colors.Accent)
                Controls = [ordered]@{
                    About = @{
                        Control = "Label"
                        Text = "About".ToUpper()
                        Font = [Font]::new("Consolas", 8, [FontStyle]::Underline)
                        Anchor = "Left"
                        TextAlign = "MiddleLeft"
                        Cursor = [Cursors]::Hand
                        ToolTip = "Informationen über das Skript"
                        Add_Click = { Start-Form $FormConfig.About }
                    }
                    Version = @{
                        Control = "Label"
                        Text = "Version $($AppInfo.Version)"
                        Font = [Font]::new("Consolas", 8, [FontStyle]::Italic)
                        Anchor = "None"
                        TextAlign = "MiddleCenter"
                    }
                    Details = @{
                        Control = "Label"
                        Text = "Optionen".ToUpper()
                        Font = [Font]::new("Consolas", 8, [FontStyle]::Underline)
                        Anchor = "Right"
                        TextAlign = "MiddleRight"
                        Cursor = [Cursors]::Hand
                        ToolTip = "Weitere Optionen und Einstellungen"
                        Add_Click = { Start-Form $FormConfig.Settings }
                    }
                }
            }
        }
        Events = @{
            Load = {
                $this.Text += if ($AppInfo.AdminRights) { " – Administrator".ToUpper() }
            }
            Shown = { 
                $this.Activate()
                $infoBox = $this.Controls["MainPanel"].Controls["InfoBox"]
                $sysInfoText = @"
                  - Systeminformationen -
- Betriebssystem: $($SystemInfo.ProductName) $($SystemInfo.DisplayVersion) (Build $($SystemInfo.CurrentBuild))
- Architektur: $($SystemInfo.Architecture)
- Systemlaufwerk: $($SystemInfo.SystemDrive)
- Systemverzeichnis: $($SystemInfo.SystemRoot)
- Prozessoranzahl: $($SystemInfo.ProcessorCount)
- .NET-Version: $($SystemInfo.CLRVersion)
"@
                $infoBox.Text += $sysInfoText
            }
            FormClosed = { [System.Environment]::Exit(0) }
        }
            
    }
    About = @{
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
    Debloat = @{
        Properties  = @{
            Text = "Tweaks & Debloat"
            ClientSize = [Size]::new(300,150)
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
                Column = @(
                    [System.Windows.Forms.ColumnStyle]::new("Percent", 100)
                )
                Row = @(
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
                            .\Debloat\UninstallEdge.ps1 { param($msg, $final) Update-Status -Label $processLabel -Message $msg -Delay 1 } 
                            $processLabel.Visible = $false
                        }
                    }   
                    HideStartMenuIcons = @{
                        Control = "Button"
                        Text = "Startmenü aufräumen"
                        Font = [Font]::new("Consolas", 10)
                        Dock = "Fill"
                        Add_Click = { 
                            $processLabel = $this.FindForm().Controls["ProcessLabel"]
                            .\Debloat\DebloatStartMenu.ps1 { param($msg, $final) Update-Status -Label $processLabel -Message $msg -Delay 1 } 
                            $processLabel.Visible = $false
                        }
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
                    $this.FindForm().ClientSize = if ($this.Visible) { [Size]::new(300,200) } else { [Size]::new(300,150) }
                }

            }
        }
        Events      = @{
            Closed = { $this.Dispose() }
        }
    }
}


Start-Form $FormConfig.Main
# Start-Chocolatey


<# Skript-Neustart #>
if ($global:restartScript) { 
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    [System.Environment]::Exit(0)
 }

