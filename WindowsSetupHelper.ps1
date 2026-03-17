using namespace System.Windows.Forms
using namespace System.Drawing
using namespace Console
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization
[System.Windows.Forms.Application]::EnableVisualStyles()


# Überprüfen, ob das Skript mit Administratorrechten ausgeführt wird
# if ( -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')){
#     Write-Host "Starte als Administrator neu..."
#     Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
#     [System.Environment]::Exit(0)
# }

$global:AppInfo = @{
    Name        = "Windows Setup Helper"
    Version     = "0.9.8"
    Author      = "jonnilius"
    Company     = "BORINAS"
    License     = "MIT License"

    IsAdmin     = & {
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
$global:AppDesign = @{
    ColorAccent = [ColorTranslator]::FromHtml("#C0393B")
    ColorDark   = [ColorTranslator]::FromHtml("#2D3436")
    ColorWhite  = [ColorTranslator]::FromHtml("#EEEEEE")
}
$global:Colors = @{
    Accent     = "#C0393B"
    Dark       = "#2D3436"
    White      = "#EEEEEE"
    Debug1     = "#27AE60"
    Debug2     = "#2980B9"
}
$global:FormColor = @{
    Accent     = [ColorTranslator]::FromHtml("#C0393B")
    Dark       = [ColorTranslator]::FromHtml("#2D3436")
    White      = [ColorTranslator]::FromHtml("#EEEEEE")
    Debug1     = [ColorTranslator]::FromHtml("#27AE60")
    Debug2     = [ColorTranslator]::FromHtml("#2980B9")
}

# $ErrorActionPreference = "SilentlyContinue"

$env:PSModulePath += ";$PSScriptRoot\Modules"
Import-Module "$PSScriptRoot\Modules\Utils.psm1"
Import-Module "$PSScriptRoot\Modules\FormBuilder.psm1"
Import-Module "$PSScriptRoot\Modules\Chocolatey.psm1"


$script:ChocoSetupList = Read-Chocolatey -SetupList
$DebloatList = @{
    "OneDrive" = @{
        Name            = "OneDrive"
        Installed       = Get-Command -Name "OneDrive.exe" -ErrorAction SilentlyContinue
        UninstallScript = { Test-Path .\Debloat\Uninstall-OneDrive.ps1 }
    }
    "Edge" = @{
        Name            = "Microsoft Edge"
        Installed       = Get-Package -Name "Microsoft Edge" -ErrorAction SilentlyContinue
        UninstallScript = { Test-Path .\Debloat\Uninstall-MicrosoftEdge.ps1 }
    }
    "StartMenu" = @{
        Name            = "Startmenü-Icons"
        Installed       = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -ErrorAction SilentlyContinue
        UninstallScript = { Test-Path .\Debloat\Unregister-StartMenuIcons.ps1 }
    }
    "WinGet" = @{
        Name            = "WinGet"
        Installed       = Get-Command -Name "winget.exe" -ErrorAction SilentlyContinue
        UninstallScript = { Test-Path .\Debloat\Uninstall-WinGet.ps1 }
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
            ClientSize  = [Size]::new(360,400) # Breite, Höhe
            Icon        = Get-Icon "Main"
            Padding     = [Padding]::new(10,0,10,0)
            ForeColor   = $FormColor.Dark
            BackColor   = $FormColor.Accent
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
                            ChocolateyButton = @{
                                Control = "Button"
                                Text    = "Chocolatey Software"
                                Dock    = "Fill"
                                Font    = Get-Font
                                Margin  = [Padding]::new(5)

                                Add_Click = { Start-Form $FormConfig.Chocolatey }
                            }
                            DebloatButton = @{
                                Control = "Button"
                                Text    = "Debloater"
                                Dock    = "Fill"
                                Font    = Get-Font
                                Margin  = [Padding]::new(5)

                                Add_Click = { Start-Form $FormConfig.Debloat }
                            }
                            WingetButton = @{
                                Control = "Button"
                                Text = "WinGet"
                                Margin = [Padding]::new(5)
                                Font = Get-Font
                                Dock = "Fill"
                                Visible = $false
                                Add_Click = { 
                                
                                }
                            }
                            SettingsButton = @{
                                Control = "Button"
                                Text = "Einstellungen"
                                Margin = [Padding]::new(5)
                                Font = Get-Font
                                Dock = "Fill"
                                Visible = $false
                            }
                        }
                    }
                }
            }
            PaketManagerPanel = @{
                Control = "TableLayoutPanel"
                Dock = "Bottom"
                ForeColor = $FormColor.Accent
                BackColor = $FormColor.Dark
                Padding = [Padding]::new(20,0,20,0)
                Visible = $false
                Column = @( "50", "50" )
                Row = @( "AutoSize", 50, "100")
                Controls = @{
                    Label = @{
                        Position = (0,1),1
                        Control = "Label"
                        Text = "Paket-Manager".ToUpper()
                        Font = [Font]::new("Consolas", 14, [FontStyle]::Underline)
                        Dock = "Top"
                        Height = 50
                        TextAlign = "MiddleCenter"
                        Add_Click = {
                            $mainPanel = $this.FindForm().Controls["MainPanel"]
                            $paketManagerPanel = $this.FindForm().Controls["PaketManagerPanel"]
                            $paketManagerPanel.Visible = $false
                            $mainPanel.Visible = $true
                        }
                    }
                    WingetButton = @{
                        Position = (0,2)
                        Control = "Button"
                        Name = "WingetButton"
                        Margin = [Padding]::new(0,0,0,10)
                        Text = "WinGet"
                        Font = [Font]::new("Consolas", 10)
                        Dock = "Fill"
                    }
                    ChocoButton = @{
                        Position = (1,2)
                        Control = "Button"
                        Name = "ChocoButton"
                        Margin = [Padding]::new(0,0,0,10)
                        Text = "Chocolatey"
                        Dock = "Fill"
                        Font = [Font]::new("Consolas", 10)
                        Add_Click = { Start-Form $FormConfig.Chocolatey }
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
                Control = "Label"
                Text = "WINDOWS SETUP HELPER"
                Font = [Font]::new("Consolas", 22, [FontStyle]::Bold)
                Dock = "Top"
                Height = 50
                TextAlign = "MiddleCenter"
                ToolTip = "Doppelklicken zum Neustarten des Skripts (als Administrator)"
                Add_DoubleClick = {
                    $this.FindForm().Dispose()
                    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
                    
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
            FormClosed = { [System.Environment]::Exit(0) }
            Load = { 
                $this.Text += if ($AppInfo.IsAdmin) { " – Administrator".ToUpper() } 
                $wingetButton = $this.Controls.Find("WingetButton", $true)[0]
                if (Get-Command winget -ErrorAction SilentlyContinue) {
                    $wingetButton.Text = "WinGet entfernen"
                    $wingetButton.Add_Click()
                } else {
                    $wingetButton.Text = "WinGet installieren"
                    $wingetButton.Add_Click({
                        Start-Sleep -Seconds 1
                        Install-WinGet | Out-Null
                        Start-Sleep -Seconds 1
                        [System.Windows.Forms.MessageBox]::Show(
                            "WinGet wurde erfolgreich installiert.", 
                            "Erfolg", 
                            [System.Windows.Forms.MessageBoxButtons]::OK, 
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
                    })
                }
            }
            Resize = { 
                $header = $this.Controls["Header"]
                $header.Font = [Font]::new("Consolas", $(Resize-Form $this 22), [FontStyle]::Bold)
             }
            Shown = { 
                # $this.Activate()
                $header     = $this.Controls["Header"]
                $header.Font = [Font]::new("Consolas", $(Resize-Form $this 22), [FontStyle]::Bold)

                $infoBox    = $this.Controls["MainPanel"].Controls["InfoBox"]
                $sysInfoText = @"
                  Paket-Manager:
- WinGet:   $(if (Get-Command winget -ErrorAction SilentlyContinue) { "Vorhanden" } else { "Nicht gefunden" })
- Chocolatey: $(if (Get-Command choco -ErrorAction SilentlyContinue) { "Vorhanden" } else { "Nicht gefunden" })
"@
                $infoBox.Text += $sysInfoText
            }
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
    Chocolatey = @{
        Properties  = @{
            Name        = "ChocolateyForm"
            Text        = "$($AppInfo.Name) - Chocolatey"
            ClientSize  = [Size]::new(600,300)
            Icon        = Get-Icon "Chocolatey"
        }
        Controls    = @{
            PackagePanel = @{
                Control     = "Panel"
                Name        = "PackagePanel"
                Dock        = "Fill"
                Padding     = [Padding]::new(10,10,10,5)
                Controls    = [ordered]@{
                    TabControl = @{
                        Control     = "TabControl"
                        Dock        = "Fill"
                        BackColor   = $FormColor.Dark
                        ForeColor   = $FormColor.Accent
                        Font        = [Font]::new("Consolas", 10)
                        Controls    = [ordered]@{
                            ManageTab = @{
                                Control     = "TabPage"
                                Text        = "Verwalten"
                                Name        = "ManageTab"
                                Controls    = @{
                                    InstalledList = @{
                                        Control = "ListBox"
                                        Name    = "InstalledList"
                                        Dock    = "Fill"
                                        Add_SelectedIndexChanged = {
                                            $selectLabel = $this.FindForm().Controls["PackagePanel"].Controls["SelectLabel"]
                                            $updateButton = $this.FindForm().Controls["SidebarPanel"].Controls["UpdateButton"]
                                            $removeButton = $this.FindForm().Controls["SidebarPanel"].Controls["UninstallButton"]

                                            $updateButton.Visible   = $this.SelectedItems.Count -gt 0
                                            $removeButton.Visible   = $this.SelectedItems.Count -gt 0
                                            $selectLabel.Text      = if ($this.Items.Count -eq $this.SelectedItems.Count) { "Alle abwählen" } else { "Alle auswählen" }
                                        }
                                    }
                                    Process = @{
                                        Control = "RichTextBox"
                                        Name = "Process"
                                        Dock = "Fill"
                                        TextAlign = "MiddleCenter"
                                        Visible = $false
                                    }
                                }
                                Add_Enter = {
                                    $AddList = $this.FindForm().Controls["PackagePanel"].Controls["AddList"]
                                    $installButton = $this.FindForm().Controls["SidebarPanel"].Controls["InstallButton"]

                                    $AddList.Items.Clear()
                                    $AddList.Items.AddRange((Read-Chocolatey -SetupList).ToArray())
                                    $installButton.Visible = $false
                                }
                            }
                            AddTab = @{
                                Control     = "TabPage"
                                Text        = "Hinzufügen"
                                Name        = "AddTab"
                                Controls    = @{
                                    AddList = @{
                                        Control     = "CheckedListBox"
                                        Name        = "AddList"
                                        Items       = Read-Chocolatey -SetupList
                                        Add_ItemCheck = {
                                            param($src, $e)
                                            $count = $src.CheckedItems.Count
                                            if ($e.NewValue -eq [CheckState]::Checked) { $count++ } else { $count-- }

                                            $form = $this.FindForm()
                                            $form.Controls["SidebarPanel"].Controls["InstallButton"].Visible = $count -gt 0
                                        }
                                    }
                                    Process = @{
                                        Control = "RichTextBox"
                                        Name = "Process"
                                        Dock = "Fill"
                                        TextAlign = "MiddleCenter"
                                        Visible = $false
                                    }
                                }
                            }
                        }
                        Add_SelectedIndexChanged = {
                            $selectedTab    = $this.SelectedTab
                            $sidebarPanel   = $this.FindForm().Controls["SidebarPanel"]

                            
                            # ManageTab
                            $installedList = $this.Controls["ManageTab"].Controls["InstalledList"]
                            $updateButton   = $sidebarPanel.Controls["UpdateButton"]
                            $removeButton   = $sidebarPanel.Controls["UninstallButton"]
                            if ($selectedTab.Name -ne "ManageTab") {
                                $installedList.ClearSelected()
                                $updateButton.Visible   = $false
                                $removeButton.Visible   = $false
                            }
                            
                            # AddTab
                            $addList = $this.Controls["AddTab"].Controls["AddList"]
                            $installButton  = $sidebarPanel.Controls["InstallButton"]
                            if ($selectedTab.Name -ne "AddTab") {
                                $addList.ClearSelected()
                                foreach ($index in $addList.CheckedIndices) { $addList.SetItemChecked($index, $false) }
                                $installButton.Visible  = $false
                            }
                            
                        }
                    }
                    SelectLabel = @{
                        Control = "Label"
                        Text = "Alle auswählen"
                        ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
                        TextAlign = "MiddleCenter"
                        Height = 30
                        Font = [Font]::new("Consolas", 8)
                        Dock = "Bottom"
                        Cursor = [Cursors]::Hand
                        Add_Click = {
                            $tabControl     = $this.FindForm().Controls["PackagePanel"].Controls["TabControl"]
                            $selectedTab    = $tabControl.SelectedTab

                            switch ($selectedTab.Name) {
                                "ManageTab" { 
                                    $installedList = $tabControl.Controls["ManageTab"].Controls["InstalledList"]
                                    if ($installedList.SelectedItems.Count -eq $installedList.Items.Count) {
                                        $installedList.ClearSelected()
                                        $this.Text = "Alle auswählen"
                                    } else {
                                        for ($i = 0; $i -lt $installedList.Items.Count; $i++) { $installedList.SetSelected($i, $true) }
                                        $this.Text = "Alle abwählen"
                                    }
                                }
                                "AddTab" { 
                                    $addList = $tabControl.Controls["AddTab"].Controls["AddList"]
                                    if ($addList.CheckedItems.Count -eq $addList.Items.Count) {
                                        for ($i = 0; $i -lt $addList.Items.Count; $i++) { $addList.SetItemChecked($i, $false) }
                                        $this.Text = "Alle auswählen"
                                    } else {
                                        for ($i = 0; $i -lt $addList.Items.Count; $i++) { $addList.SetItemChecked($i, $true) }
                                        $this.Text = "Alle abwählen"
                                    }
                                }
                            }
                        }
                    }
                }
            }
            SidebarPanel = @{
                Control     = "Panel"
                Name        = "SidebarPanel"
                Dock        = "Right"
                ForeColor   = [ColorTranslator]::FromHtml($Colors.Dark)
                BackColor   = [ColorTranslator]::FromHtml($Colors.Accent)
                Padding     = [Padding]::new(10,5,0,0)
                Controls    = [ordered]@{
                    UninstallChocoButton = @{
                        Control = "Button"
                        Text = "Chocolatey entfernen"
                        Dock = "Top"
                        Font = [Font]::new("Consolas", 8, [FontStyle]::Bold)
                        Add_Click = { 
                            $confirm = Show-MessageBox "ConfirmUninstallChocolatey"
                            # $confirm = [System.Windows.Forms.MessageBox]::Show("Möchten Sie Chocolatey wirklich entfernen?", "Bestätigung", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
                            if ($confirm -eq [System.Windows.Forms.DialogResult]::No) { return }
                            else { $form = $this.FindForm() }
                            
                            $form.Cursor = [Cursors]::AppStarting
                            
                            Start-Sleep -Seconds 1
                            Uninstall-Chocolatey | Out-Null
                            $form.Cursor = [Cursors]::Default
                            Start-Sleep -Seconds 1
                            Show-MessageBox "UninstallChocolateySuccess"
                        }
                    }
                    InstallChocoButton = @{
                        Control = "Button"
                        Text = "Chocolatey hinzufügen"
                        Dock = "Top"
                        Font = [Font]::new("Consolas", 8, [FontStyle]::Bold)
                        Add_Click = { 
                            $form = $this.FindForm()
                            $form.Cursor = [Cursors]::AppStarting
                            Start-Sleep -Seconds 1
                            Install-Chocolatey | Out-Null
                            $form.Cursor = [Cursors]::Default
                            Start-Sleep -Seconds 1
                            Show-MessageBox "InstallChocolateySuccess"
                        }
                    }
                    VersionLabel = @{
                        Control = "Label"
                        Text = "Version: $(Read-Chocolatey -Version)"
                        TextAlign = "MiddleCenter"
                        Dock = "Top"
                        Height = 30
                        Font = [Font]::new("Consolas", 10, [FontStyle]::Bold)
                    }
                    NameLabel = @{
                        Control = "Label"
                        Text = "Chocolatey"
                        TextAlign = "MiddleCenter"
                        Dock = "Top"
                        # Font = [Font]::new("Cascadia Code", 12, [FontStyle]::Bold)
                        Font = [Font]::new("Cascadia Code", 12, [FontStyle]::Bold)
                    }

                    UpdateButton = @{
                        Control = "Button"
                        Name    = "UpdateButton"
                        Text    = "Aktualisieren"
                        Visible = $false
                        Dock    = "Bottom"
                        Font = [Font]::new("Tahoma", 8, [FontStyle]::Bold)
                        Add_Click = { UpdateChocoApps $this.FindForm() }
                    }
                    InstallButton = @{
                        Control = "Button"
                        Name    = "InstallButton"
                        Visible = $false
                        Text    = "Installieren"
                        Dock    = "Bottom"
                        Font    = [Font]::new("Tahoma", 8, [FontStyle]::Bold)
                        
                        Add_Click = { InstallChocoApps $this.FindForm() }
                    }
                    UninstallButton = @{
                        Control = "Button"
                        Name    = "UninstallButton"
                        Visible = $false
                        Text    = "Deinstallieren"
                        Dock    = "Bottom"
                        Font    = [Font]::new("Tahoma", 8, [FontStyle]::Bold)
                        
                        Add_Click = { UninstallChocoApps $this.FindForm() }
                    }
                }
            }
        }
        Events      = @{
            Shown = { 
                $tabControl = $this.Controls["PackagePanel"].Controls["TabControl"]

                # App-Liste laden
                $InstalledList = $tabControl.Controls["ManageTab"].Controls["InstalledList"]
                $AppList = Read-Chocolatey -AppList
                foreach ($program in $AppList) { [void]$InstalledList.Items.Add($program) }

                # Chocolatey-Installationsstatus
                $sidebarPanel   = $this.Controls["SidebarPanel"]
                if (Read-Chocolatey -Installed) {
                    $sidebarPanel.Controls["InstallChocoButton"].Enabled = $false
                } else {
                    $sidebarPanel.Controls["UninstallChocoButton"].Enabled = $false
                }

            }
        }
    }
}


Start-Form $FormConfig.Main


