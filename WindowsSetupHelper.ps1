using namespace System.Windows.Forms
using namespace System.Drawing
using namespace Console

param ( [switch]$Force )
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization
[Application]::EnableVisualStyles()

$global:ErrorActionPreference = "SilentlyContinue"



# App-Info
$Manifest = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot "WindowsSetupHelper.psd1")
$global:AppInfo = @{
    Name        = "Windows Setup Helper"
    Version     = $Manifest.ModuleVersion
    Author      = $Manifest.Author
    Company     = $Manifest.CompanyName
    License     = "MIT License"
}


# App-Konfiguration
$global:AppConfig = @{
    ModulePath  = "$PSScriptRoot\Modules"
    IconPath    = "$PSScriptRoot\Assets\Icons"
    # HideShell   = $true
}
if ($AppConfig.ModulePath -notin ($env:PSModulePath.Split(";"))) { $env:PSModulePath += ";$($AppConfig.ModulePath)" }


# Initialisiere Konfiguration
Set-AppConfig
Set-Administrator -Command $PSCommandPath -Enable


<# FORM-DATA ############################################################################>
$FormConfig = @{
    Main        = @{
        Properties  = @{
            ClientSize  = [Size]::new(450,450) # Breite, Höhe
            MinimumSize = [Size]::new(450,450)
            Padding     = [Padding]::new(10,0,10,0)
        }
        Controls    = [ordered]@{
            TabPanel = @{
                Control   = "Panel"
                Dock      = "Fill"
                Padding   = [Padding]::new(0)
                Controls  = @{
                    TabControl = @{
                        Control     = "TabControl"
                        MultiLine   = $true
                        Controls    = [ordered]@{
                            StartTab     = @{
                                Text        = "Start"
                                Controls    = [ordered]@{
                                    MainTable = @{
                                        Control     = "TableLayoutPanel"
                                        Dock        = "Fill"
                                        Padding     = [Padding]::new(10)
                                        Column      = @( "35", "50" )
                                        Row         = @( 35, 25, 25, 30, 30, 30, 30, 30, "AutoSize" )
                                        Controls    = [ordered]@{
                                            StartTitle = @{
                                                ColumnSpan  = 2
                                                Control     = "Label"
                                                Text        = "Start-Einstellungen"
                                            }
                                            StartLabel = @{
                                                Control     = "Label"
                                                Text        = ""
                                            }
                                            StartValue = @{
                                                Control     = "Label"
                                                Text        = "Randrom Text"
                                            }


                                        }
                                    }
                                }
                            }
                            TweakTab  = @{
                                Text        = "Tweaks"
                                Controls    = @{
                                    TableLayout = @{
                                        Control     = "TableLayoutPanel"
                                        Padding     = [Padding]::new(0)
                                        Column      = @( "50", "50" )
                                        Row         = @( 40, 25, 25, 50, "AutoSize" )
                                        Controls    = [ordered]@{
                                            # Column 1 – Programme 
                                            ProgramLabel = @{
                                                Control     = "Label"
                                                Text        = "Programme"
                                                Font        = Get-Font -Preset "TableTitle"
                                                Position    = 0,0
                                            }
                                            UninstallOneDrive = @{
                                                Control     = "Label"
                                                Text        = "OneDrive entfernen"
                                                Font        = Get-Font -Preset "TableLink"
                                                Position    = 0,1
                                                Hover       = "Underline"
                                                Cursor      = Get-Cursor "Hand"
                                                
                                                Add_MouseEnter  = { $this.Font = Get-Font -Preset "TableLink" -Style @("Italic","Underline") }
                                                Add_MouseLeave  = { $this.Font = Get-Font -Preset "TableLink" -Style "Italic" }
                                                Add_Click       = { & (Join-Path $PSScriptRoot "Scripts/Uninstall-OneDrive.ps1") }
                                            }
                                            UninstallEdge = @{
                                                Control     = "Label"
                                                Text        = "Microsoft Edge entfernen"
                                                Font        = Get-Font -Preset "TableLink"
                                                Position    = 0,2
                                                Cursor      = Get-Cursor "Hand"

                                                Add_MouseEnter  = { $this.Font = Get-Font -Preset "TableLink" -Style @("Italic","Underline") }
                                                Add_MouseLeave  = { $this.Font = Get-Font -Preset "TableLink" -Style "Italic" }
                                                Add_Click       = { & (Join-Path $PSScriptRoot "Scripts/Uninstall-MicrosoftEdge.ps1") }
                                            }   
                                            # Column 2 – System
                                            SystemLabel = @{
                                                Control     = "Label"
                                                Text        = "System"
                                                Font        = Get-Font -Preset "TableTitle"
                                                TextAlign   = "MiddleCenter"
                                                Position    = 1,0
                                            }
                                            HideStartMenuIcons = @{
                                                Control     = "Button"
                                                Text        = "Startmenü aufräumen"
                                                Font        = Get-Font -Preset "TableButton"
                                                Position    = 1,1
                                                Margin      = [Padding]::new(20,0,20,0)
                                                Add_Click   = { & (Join-Path $PSScriptRoot "Scripts/Remove-StartMenuIcons.ps1") }
                                            }
                                            DisableTelemetry = @{
                                                Control     = "Button"
                                                Text        = "Telemetrie deaktivieren"
                                                Font        = Get-Font -Preset "TableButton"
                                                Position    = 1,2
                                                Margin      = [Padding]::new(20,0,20,0)
                                                Add_Click   = { & (Join-Path $PSScriptRoot "Scripts/Disable-Telemetry.ps1") }
                                            }
                                        }
                                    }
                                }
                            }
                            PackageTab  = @{
                                Text        = "Programme"
                                Padding    = [Padding]::new(10)
                                Controls    = @{
                                    InstalledPackagesListBox = @{
                                        Control         = "ListView"
                                        Dock            = "Fill"
                                        HideSelection   = $false
                                        MultiSelect     = $true
                                        Columns         = @( @("Name", 310), @("ID", 310), @("Version", 150), @("Quelle", 230) )
                                        Add_MouseDown   = {
                                            param($listView, $e)
                                            if ($e.Button -ne [MouseButtons]::Right) { return }

                                            $item = $listView.GetItemAt($e.X, $e.Y)
                                            if (-not $item) { return }

                                            if (-not $item.Selected) {
                                                $listView.SelectedItems.Clear()
                                                $item.Selected = $true
                                            }
                                        }
                                    }
                                    PaketManagerTable = @{
                                        Control     = "TableLayoutPanel"
                                        Column      = @( "40", 100, 100, 100 )
                                        Dock        = "Bottom"
                                        Height      = 40
                                        Controls    = [ordered]@{
                                            PaketManagerLabel = @{
                                                Control     = "Label"
                                                Text        = "Paket-Manager"
                                                Font        = Get-Font -Preset "TableLabel"
                                            }
                                            ChocolateyButton = @{
                                                # Position    = 1,0
                                                Control     = "Button"
                                                Text        = "Chocolatey"
                                                Font        = Get-Font -Preset "TableButton"
                                                Width       = 100
                                                Anchor      = "Right"
                                                Add_Click   = { 
                                                    Import-Module Chocolatey
                                                    Start-ChocolateyUI $this
                                                }
                                            }
                                            WingetButton = @{
                                                Control     = "Button"
                                                Text        = "WinGet"
                                                Font        = Get-Font -Preset "TableButton"
                                                Width       = 100
                                                Anchor      = "Left"
                                                Add_Click   = { 
                                                    Import-Module WinGet
                                                    Start-WinGetUI $this
                                                }
                                            }
                                            CargoButton = @{
                                                Control     = "Button"
                                                Text        = "Cargo (Rust)"
                                                Font        = Get-Font -Preset "TableButton"
                                                Width       = 100
                                                Anchor      = "Left"
                                                Add_Click   = { 
                                                    Import-Module Cargo
                                                    Start-CargoUI $this
                                                }
                                            }

                                        }
                                    }
                                }
                                Add_Enter = {
                                    $listView = Get-Control $this "InstalledPackagesListBox"
                                    if (-not $listView) { return }
                                    if (-not $listView.ContextMenuStrip) { 
                                        $listView.ContextMenuStrip = New-ContextMenu @{
                                            Items = @{
                                                ReinstallItem = @{
                                                    Text    = "Neu installieren"
                                                    Image   = "reinstall.png"
                                                    Add_Click = {
                                                        $listView = $this.Owner.SourceControl
                                                        if (-not $listView) { return }

                                                        $programs = @($listView.SelectedItems | ForEach-Object { $_.Tag })
                                                        foreach ($program in $programs) {
                                                            Show-ProgressDialog "Neuinstallation von $($program.Name)..." "Starte Neuinstallation von $($program.Name)..."
                                                            Uninstall-Program $program
                                                            Install-Program $program
                                                        }
                                                        Update-InstalledProgramsList -ListView $listView
                                                    }
                                                }
                                                UninstallItem = @{
                                                    Text    = "Deinstallieren"
                                                    Image   = "uninstall.png"
                                                    Add_Click = {
                                                        $listView = $this.Owner.SourceControl
                                                        if (-not $listView) { return }

                                                        $programs = @($listView.SelectedItems | ForEach-Object { $_.Tag })
                                                        foreach ($program in $programs) {
                                                            Show-ProgressDialog "Deinstallation von $($program.Name)..." "Starte Deinstallation von $($program.Name)..."
                                                            Uninstall-Program $program
                                                        }
                                                        Update-InstalledProgramsList -ListView $listView
                                                    }
                                                }
                                                DetailItem = @{
                                                    Text    = "Details anzeigen"
                                                    Image   = "details.png"
                                                    Add_Click = {
                                                        $listView = $this.Owner.SourceControl
                                                        if (-not $listView) { return }

                                                        $programs = @($listView.SelectedItems | ForEach-Object { $_.Tag })
                                                        foreach ($program in $programs) {
                                                            Show-ProgramDetails $program
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    
                                    }
                                }
                            }
                            PowerTab = @{
                                Text        = "Energieoptionen"
                                Controls    = @{
                                    PowerTable = @{
                                        Control     = "TableLayoutPanel"
                                        Padding     = [Padding]::new(10)
                                        Column      = @( "55", "25", "20" )
                                        Row         = @( 30, 30, 30, 30, 30, 30, 30, 30, 40, "AutoSize" )
                                        Controls    = [ordered]@{

                                            # Row 1 – Im Netzbetrieb
                                            PowerLabelDC = @{
                                                # Position    = 0,0
                                                ColumnSpan  = 3
                                                Control     = "Label"
                                                Text        = "Im Netzbetrieb"
                                                Font        = Get-Font -Preset "TableTitle"
                                                TextAlign   = "MiddleCenter"
                                                Padding     = [Padding]::new(0,10,0,0)
                                            }

                                            # Row 2 – Im Netzbetrieb (Energiesparmodus)
                                            StandbyLabelAC = @{
                                                # Position    = 0,1
                                                Control     = "Label"
                                                Text        = "Energiesparmodus:"
                                                TextAlign   = "MiddleRight"
                                                Font        = Get-Font -Preset "TableLabel"
                                            }
                                            StandbyValueAC = @{
                                                # Position    = 1,1
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "AC" "Standby" -TextOutput
                                                Font        = Get-Font -Preset "TableText"
                                            }
                                            StandbyButtonAC = @{
                                                # Position    = 2,1
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font -Preset "TableButton"

                                                Add_Click   = { 
                                                    Update-PowerStatus -PowerScheme "AC" -StatusType "Standby"
                                                    $this.FindForm().Controls.Find("StandbyValueAC", $true)[0].Text = Get-PowerStatus "AC" "Standby" -TextOutput
                                                }
                                            }

                                            # Row 3 – Im Netzbetrieb (Ruhezustand)
                                            HibernateLabelAC = @{
                                                # Position    = 0,2
                                                Control     = "Label"
                                                Text        = "Ruhezustand:"
                                                Font        = Get-Font -Preset "TableLabel"
                                                TextAlign   = "MiddleRight"
                                            }
                                            HibernateValueAC = @{
                                                # Position    = 1,2
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "AC" "Hibernate" -TextOutput
                                                Font        = Get-Font -Preset "TableText"
                                            }
                                            HibernateButtonAC = @{
                                                # Position    = 2,2
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font -Preset "TableButton"
                                                Add_Click   = { 
                                                    Update-PowerStatus -PowerScheme "AC" -StatusType "Hibernate"
                                                    $this.FindForm().Controls.Find("HibernateValueAC", $true)[0].Text = Get-PowerStatus "AC" "Hibernate" -TextOutput
                                                 }
                                            }

                                            # Row 4 – Im Netzbetrieb (Monitor ausschalten)
                                            MonitorLabelAC = @{
                                                # Position    = 0,3
                                                Control     = "Label"
                                                Text        = "Monitor ausschalten:"
                                                Font        = Get-Font -Preset "TableLabel"
                                                TextAlign   = "MiddleRight"
                                            }
                                            MonitorValueAC = @{
                                                # Position    = 1,3
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "AC" "Monitor" -TextOutput
                                                Font        = Get-Font -Preset "TableText"
                                            }
                                            MonitorButtonAC = @{
                                                # Position    = 2,3
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font -Preset "TableButton"
                                                Add_Click   = { 
                                                    Update-PowerStatus -PowerScheme "AC" -StatusType "Monitor"
                                                    $this.FindForm().Controls.Find("MonitorValueAC", $true)[0].Text = Get-PowerStatus "AC" "Monitor" -TextOutput
                                                 }
                                            }
                                            
                                            # Row 5 – Im Akkubetrieb
                                            BatteryLabelDC = @{
                                                # Position    = 0,4
                                                ColumnSpan  = 3
                                                Control     = "Label"
                                                Text        = "Im Akkubetrieb"
                                                Font        =  Get-Font -Preset "TableTitle"
                                                TextAlign   = "TopCenter"
                                                Padding     = [Padding]::new(0,10,0,0)
                                            }

                                            # Row 6 – Im Akkubetrieb (Energiesparmodus)
                                            StandbyLabelDC = @{
                                                # Position    = 0,5
                                                Control     = "Label"
                                                Text        = "Energiesparmodus:"
                                                Font        = Get-Font -Preset "TableLabel"
                                                TextAlign   = "MiddleRight"
                                            }
                                            StandbyValueDC = @{
                                                # Position    = 1,5
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "DC" "Standby" -TextOutput
                                                Font        = Get-Font -Preset "TableText"
                                            }
                                            StandbyButtonDC = @{
                                                # Position    = 2,5
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font -Preset "TableButton"
                                                Add_Click   = { 
                                                    Update-PowerStatus -PowerScheme "DC" -StatusType "Standby"
                                                    $this.FindForm().Controls.Find("StandbyValueDC", $true)[0].Text = Get-PowerStatus "DC" "Standby" -TextOutput
                                                 }
                                            }

                                            # Row 7 – Im Akkubetrieb (Ruhezustand)
                                            HibernateLabelDC = @{
                                                # Position    = 0,6
                                                Control     = "Label"
                                                Text        = "Ruhezustand:"
                                                Font        = Get-Font -Preset "TableLabel"
                                                TextAlign   = "MiddleRight"
                                            }
                                            HibernateValueDC = @{
                                                # Position    = 1,6
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "DC" "Hibernate" -TextOutput
                                                Font        = Get-Font -Preset "TableText"
                                            }
                                            HibernateButtonDC = @{
                                                # Position    = 2,6
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font -Preset "TableButton"
                                                Add_Click   = { 
                                                    Update-PowerStatus -PowerScheme "DC" -StatusType "Hibernate"
                                                    $this.FindForm().Controls.Find("HibernateValueDC", $true)[0].Text = Get-PowerStatus "DC" "Hibernate" -TextOutput
                                                }
                                            }

                                            # Row 8 – Im Akkubetrieb (Monitor ausschalten)
                                            MonitorLabelDC = @{
                                                # Position    = 0,7
                                                Control     = "Label"
                                                Text        = "Monitor ausschalten:"
                                                Font        = Get-Font -Preset "TableLabel"
                                                TextAlign   = "MiddleRight"
                                            }
                                            MonitorValueDC = @{
                                                # Position    = 1,7
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "DC" "Monitor" -TextOutput
                                                Font        = Get-Font -Preset "TableText"
                                            }
                                            MonitorButtonDC = @{
                                                # Position    = 2,7
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font -Preset "TableButton"
                                                Add_Click   = { 
                                                    Update-PowerStatus -PowerScheme "DC" -StatusType "Monitor"
                                                    $this.FindForm().Controls.Find("MonitorValueDC", $true)[0].Text = Get-PowerStatus "DC" "Monitor" -TextOutput
                                                }
                                            }

                                            # Row 9 – Energiesparmodus deaktivieren
                                            DisableSleep = @{
                                                Visible     = $false
                                                # Position    = 0,8
                                                ColumnSpan  = 3
                                                Control     = "Button"
                                                Text        = "Energiesparmodus deaktivieren"
                                                Font        = Get-Font -Preset "TableButton"

                                                Add_Click = { 
                                                    Set-PowerStatus -PowerScheme "AC" -StatusType "Standby" -Minutes 0
                                                    $this.FindForm().Controls.Find("StandbyValueAC", $true)[0].Text = Get-PowerStatus "AC" "Standby" -TextOutput

                                                    Set-PowerStatus -PowerScheme "AC" -StatusType "Hibernate" -Minutes 0
                                                    $this.FindForm().Controls.Find("HibernateValueAC", $true)[0].Text = Get-PowerStatus "AC" "Hibernate" -TextOutput

                                                    Set-PowerStatus -PowerScheme "AC" -StatusType "Monitor" -Minutes 0
                                                    $this.FindForm().Controls.Find("MonitorValueAC", $true)[0].Text = Get-PowerStatus "AC" "Monitor" -TextOutput

                                                    Set-PowerStatus -PowerScheme "DC" -StatusType "Standby" -Minutes 0
                                                    $this.FindForm().Controls.Find("StandbyValueDC", $true)[0].Text = Get-PowerStatus "DC" "Standby" -TextOutput

                                                    Set-PowerStatus -PowerScheme "DC" -StatusType "Hibernate" -Minutes 0
                                                    $this.FindForm().Controls.Find("HibernateValueDC", $true)[0].Text = Get-PowerStatus "DC" "Hibernate" -TextOutput

                                                    Set-PowerStatus -PowerScheme "DC" -StatusType "Monitor" -Minutes 0
                                                    $this.FindForm().Controls.Find("MonitorValueDC", $true)[0].Text = Get-PowerStatus "DC" "Monitor" -TextOutput

                                                    $this.Visible = $false
                                                }
                                                Add_VisibleChanged = {
                                                    if ($this.Visible) { $this.FindForm().MinimumSize = [Size]::new(410,450) } else { $this.FindForm().MinimumSize = [Size]::new(410,420) }
                                                }
                                            }
                                        }
                                    }
                                }
                                Add_Enter = {
                                    $PowerValues = @{
                                        "StandbyValueAC"    = Get-PowerStatus "AC" "Standby" -TextOutput
                                        "HibernateValueAC"  = Get-PowerStatus "AC" "Hibernate" -TextOutput
                                        "MonitorValueAC"    = Get-PowerStatus "AC" "Monitor" -TextOutput
                                        "StandbyValueDC"    = Get-PowerStatus "DC" "Standby" -TextOutput
                                        "HibernateValueDC"  = Get-PowerStatus "DC" "Hibernate" -TextOutput
                                        "MonitorValueDC"    = Get-PowerStatus "DC" "Monitor" -TextOutput
                                    }
                                    foreach ($key in $PowerValues.Keys) {
                                        $label = $this.FindForm().Controls.Find($key, $true)[0]
                                        $label.Text = $PowerValues[$key]
                                        if ($label.Text -ne "Nie") {
                                            $this.FindForm().Controls.Find("DisableSleep", $true)[0].Visible = $true
                                        } 
                                        $label.Add_TextChanged({
                                                if ($this.Text -eq "Nie") {
                                                $this.FindForm().Controls.Find("DisableSleep", $true)[0].Visible = $false
                                            } elseif ($this.Text -ne "Nie") {
                                                $this.FindForm().Controls.Find("DisableSleep", $true)[0].Visible = $true
                                            }
                                        })
                                    }
                                }
                            }
                            OfficeTab = @{
                                Text        = "Office"
                                Controls    = @{
                                    OfficeTable  = @{
                                        Control  = "TableLayoutPanel"
                                        Row      = @( "15", "12", "15", "15", "15" ,"15", "15" )
                                        Padding  = [Padding]::new(10,5,10,10)
                                        Controls = [ordered]@{
                                            InstallOfficeLabel    = @{
                                                Control     = "Label"
                                                Text        = "Office Installieren"
                                                Font        = Get-Font -Preset "TableTitle"
                                                Padding     = [Padding]::new(0,10,0,0)
                                            }
                                            InstallOfficeDropdown = @{
                                                Control     = "TableLayoutPanel"
                                                Column      = @( "20", "30", "50" )
                                                Controls    = [ordered]@{
                                                    LicenseList = @{
                                                        Control     = "ComboBox"
                                                        Add_SelectedIndexChanged = { Update-InstallDropdown $this }
                                                    }
                                                    VersionList = @{
                                                        Control     = "ComboBox"
                                                        Add_SelectedIndexChanged = { Update-InstallDropdown $this }
                                                    }
                                                    EditionList = @{
                                                        Control     = "ComboBox"
                                                    }
                                                }
                                            }
                                            InstallOfficeButtons  = @{
                                                Control     = "TableLayoutPanel"
                                                Column      = @( "35", "35", "30" )
                                                Controls    = [ordered]@{
                                                    OnlineInstaller32 = @{
                                                        Control     = "Button"
                                                        Text        = "Online (32-bit)"
                                                        Font        = Get-Font -Preset "TableButton"
                                                        Add_Click   = { 
                                                            Install-Office $this "Online" "x86"
                                                            Update-OfficeDropdown $this 
                                                        }
                                                    }
                                                    OnlineInstaller64 = @{
                                                        Control     = "Button"
                                                        Text        = "Online (64-bit)"
                                                        Font        = Get-Font -Preset "TableButton"
                                                        Add_Click   = { 
                                                            Install-Office $this "Online" "x64"
                                                            Update-OfficeDropdown $this 
                                                        }
                                                    }
                                                    OfflineInstaller  = @{
                                                        Control     = "Button"
                                                        Text        = "Offline"
                                                        Font        = Get-Font -Preset "TableButton"
                                                        Add_Click   = { 
                                                            Install-Office $this "Offline"
                                                            Update-OfficeDropdown $this 
                                                        }
                                                    }
                                                }
                                            }

                                            UninstallOfficeLabel  = @{
                                                Control     = "Label"
                                                Text        = "Office Deinstallieren"
                                                Font        = Get-Font -Preset "TableTitle"
                                                Padding     = [Padding]::new(0,10,0,0)
                                            }
                                            UninstallOfficePanel  = @{
                                                Control     = "TableLayoutPanel"
                                                Column      = @( "60", "40" )
                                                Controls    = [ordered]@{
                                                    InstalledOfficeList     = @{
                                                        Control     = "ComboBox"
                                                        Anchor      = "Left, Right"
                                                    }
                                                    UninstallOfficeButton   = @{
                                                        Control     = "Button"
                                                        Text        = "Deinstallieren"
                                                        Font        = Get-Font -Preset "TableButton"
                                                        Add_Click   = { 
                                                            $installedOfficeList = Get-Control $this "InstalledOfficeList"
                                                            if ($installedOfficeList.SelectedItem) {
                                                                Uninstall-Office $this.FindForm() $installedOfficeList.SelectedItem
                                                                Update-OfficeDropdown $this
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            ActivateOfficeLabel   = @{
                                                Control     = "Label"
                                                Text        = "Office Aktivieren"
                                                Font        = Get-Font -Preset "TableTitle"
                                                Padding     = [Padding]::new(0,10,0,0)
                                            }
                                            ActivateOfficePanel   = @{
                                                Control     = "TableLayoutPanel"
                                                Column      = @( "60", "40" )
                                                Controls    = [ordered]@{
                                                    ActivateOfficeList   = @{
                                                        Control     = "ComboBox"
                                                        Anchor      = "Left, Right"
                                                    }
                                                    ActivateOfficeButton = @{
                                                        Control     = "Button"
                                                        Text        = "Aktivieren"
                                                        Font        = Get-Font -Preset "TableButton"
                                                        Add_Click   = { 
                                                            $productID = $this.Parent.Controls["ActivateOfficeList"].SelectedItem
                                                            if ($productID) {
                                                                Activate-Office $this
                                                                # Nach der Aktivierung die Dropdown-Liste aktualisieren
                                                                Update-OfficeDropdown $this
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            InfoTab = @{
                                Text        = "Info"
                                Controls    = [ordered]@{
                                    ContentPanel = @{
                                        Control     = "Panel"
                                        Dock        = "Fill"
                                        Padding     = [Padding]::new(10)
                                        AutoScroll  = $true
                                        Controls    = [ordered]@{
                                        
                                            WindowsTable = @{
                                                Control     = "TableLayoutPanel"
                                                Dock        = "Top"
                                                AutoSize   = $true
                                                AutoSizeMode = "GrowAndShrink"
                                                TextAlign  = "MiddleLeft"
                                                Column      = @( "40", "60" )
                                                Row         = @( 35, "AutoSize", "AutoSize", "AutoSize", "AutoSize", "AutoSize", "AutoSize" )
                                                Controls    = [ordered]@{
                                                    # Row 1 - Windows-Spezifikationen
                                                    WindowsInfoLabel = @{
                                                        ColumnSpan  = 2
                                                        Control     = "Label"
                                                        Text        = "Windows-Spezifikationen"
                                                    }
                                                    # Row 2 - Windows-Edition
                                                    WindowsEditionLabel = @{
                                                        Control     = "Label"
                                                        Text        = "Edition:"
                                                    }
                                                    WindowsEditionValue = @{
                                                        Control     = "Label"
                                                        Text        = "Ermittle Windows-Edition..."
                                                        Anchor      = "Left,Top,Bottom"
                                                    }
                                                    # Row 3 - Windows-Version
                                                    WindowsVersionLabel = @{
                                                        Control     = "Label"
                                                        Text        = "Version:"
                                                    }
                                                    WindowsVersionValue = @{
                                                        Control     = "Label"
                                                        Text        = "Lese Windows-Version aus..."
                                                        Anchor      = "Left,Top,Bottom"
                                                    }
                                                    # Row 4 - Windows-Buildnummer
                                                    WindowsBuildLabel = @{
                                                        Control     = "Label"
                                                        Text        = "Betriebssystembuild:"
                                                    }
                                                    WindowsBuildValue = @{
                                                        Control     = "Label"
                                                        Text        = "Frage Windows-Build ab..."
                                                        Anchor      = "Left,Top,Bottom"
                                                    }
                                                    # Row 5 - Windows-Lizenzschlüssel
                                                    WindowsKeyLabel = @{
                                                        Control     = "Label"
                                                        Text        = "Produktschlüssel:"
                                                    }
                                                    WindowsKeyValue = @{
                                                        Control     = "Label"
                                                        Text        = "Lese Produktschlüssel aus..."
                                                        Anchor      = "Left,Top,Bottom"
                                                    }
                                                }
                                            }
                                            DeviceTable = @{
                                                Control     = "TableLayoutPanel"
                                                Dock        = "Top"
                                                AutoSize    = $true
                                                AutoSizeMode = "GrowAndShrink"
                                                TextAlign   = "MiddleLeft"
                                                Column      = @( "25", "75" )
                                                Row         = @( 35, "AutoSize", "AutoSize", "AutoSize", "AutoSize", "AutoSize", "AutoSize", "AutoSize" )
                                                Controls    = [ordered]@{
                                                    # Row 1 - Gerät-Informationen
                                                    DeviceInfoLabel = @{
                                                        ColumnSpan  = 2
                                                        Control     = "Label"
                                                        Text        = "Gerätespezifikationen"
                                                    }
                                                    # Row 2 - Gerätename
                                                    DeviceNameLabel = @{
                                                        Control     = "Label"
                                                        Text        = "Gerätename:"
                                                    }
                                                    DeviceNameValue = @{
                                                        Control     = "Label"
                                                        Text        = "Lese Gerätename aus..."
                                                        Anchor      = "Left,Top,Bottom"
                                                        ContextMenu = @{
                                                            ChangeDeviceName = @{
                                                                Text = "Gerätename ändern"
                                                                Add_Click = { 
                                                                    Set-DeviceName 
                                                                    $this.Owner.SourceControl.Text = Get-SystemInfo -DeviceName
                                                                }
                                                            }
                                                        }
                                                    }
                                                    # Row 3 - Prozessor
                                                    DeviceProcessorLabel = @{
                                                        Control     = "Label"
                                                        Text        = "Prozessor:"
                                                    }
                                                    DeviceProcessorValue = @{
                                                        Control     = "Label"
                                                        Text        = "Lese Prozessor aus..."
                                                        Anchor      = "Left,Top,Bottom"
                                                    }
                                                    # Row 4 - RAM
                                                    DeviceRAMLabel = @{
                                                        Control     = "Label"
                                                        Text        = "RAM:"
                                                    }
                                                    DeviceRAMValue = @{
                                                        Control     = "Label"
                                                        Text        = "Lese RAM aus..."
                                                        Anchor      = "Left,Top,Bottom"
                                                    }
                                                    # Row 5 - Grafikkarte
                                                    DeviceGPUlLabel = @{
                                                        Control     = "Label"
                                                        Text        = "Grafikkarte:"
                                                    }
                                                    DeviceGPUValue = @{
                                                        Control     = "Label"
                                                        Text        = "Lese Grafikkarte aus..."
                                                        Anchor      = "Left,Top,Bottom"
                                                    }
                                                    # Row 6 - Speicher
                                                    DeviceStorageLabel = @{
                                                        Control     = "Label"
                                                        Text        = "Speicher:"
                                                    }
                                                    DeviceStorageValue = @{
                                                        Control     = "Label"
                                                        Text        = "Lese Speicher aus..."
                                                        Anchor      = "Left,Top,Bottom"
                                                    }
                                                    # Row 7 - Produkt-ID
                                                    ProductIDLabel = @{
                                                        Control     = "Label"
                                                        Text        = "Produkt-ID:"
                                                    }
                                                    ProductIDValue = @{
                                                        Control     = "Label"
                                                        Text        = "Lese Produkt-ID aus..."
                                                        Anchor      = "Left,Top,Bottom"
                                                    }
                                                    # Row 8 - Systemtyp
                                                    SystemTypeLabel = @{
                                                        Control     = "Label"
                                                        Text        = "Systemtyp:"
                                                    }
                                                    SystemTypeValue = @{
                                                        Control     = "Label"
                                                        Text        = "Lese Systemtyp aus..."
                                                        Anchor      = "Left,Top,Bottom"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Add_SelectedIndexChanged = {
                            param ($tabControl, $e)
                            $selectedTab = $tabControl.SelectedTab

                            switch ($selectedTab.Name) {
                                "PackageTab" { Update-InstalledProgramsList -ListView (Get-Control $this "InstalledPackagesListBox") } 
                                "PowerTab" { 
                                    # Triggern des Enter-Events, um die Werte zu aktualisieren
                                    $powerTab = Get-Control $this "PowerTab"
                                    if ($powerTab) { $powerTab.OnEnter([EventArgs]::Empty) }
                                }
                                "OfficeTab" { 
                                    Set-InstallDropdown $this
                                    Set-OfficeDropdown  $this
                                }
                                "InfoTab"    { 
                                    foreach ($table in @("WindowsTable", "DeviceTable")) {
                                        $tableControl = Get-Control $this $table
                                        if ($tableControl) {
                                            foreach ($label in $tableControl.Controls) {
                                                if ($label.Name -notlike "*Value") { continue }
                                                $name = $label.Name -replace "Value", ""
                                                $params = @{ $name = $true }
                                                $label.Text = Get-SystemInfo @params
                                                Enable-LabelCopyOnClick -Label $label
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        # Vor dem TabPage-Wechsel
                        Add_Selecting = {
                            param ($tabControl, $e)
                            $header = Get-Control $this "Header"
                            # Module nur bei Bedarf laden, um die Startzeit des Skripts zu verkürzen
                            switch ($e.TabPage.Name) {
                                "StartTab"      { $header.Text = $AppInfo.Name.ToUpper() }
                                "PackageTab"    { $header.Text = "PROGRAMMVERWALTUNG"   ; Import-Module PackageManager }
                                "PowerTab"      { $header.Text = "ENERGIEOPTIONEN"      ; Import-Module PowerStatus }
                                "OfficeTab"     { $header.Text = "OfficeR"              ; Import-Module OfficeR }
                                "InfoTab"       { $header.Text = "SYSTEMINFORMATIONEN"  ; Import-Module SystemInfo }
                                default { $header.Refresh() }
                            }
                        }
                        # Nach dem TabPage-Wechsel
                        Add_Selected = {
                            param ($tabControl, $e)
                            
                            switch ($tabControl.SelectedTab.Name) {
                                "PackageTab" { $this.FindForm().MinimumSize = [Size]::new(1000,500) }
                                "PowerTab"   { $this.FindForm().MinimumSize = [Size]::new(550,400) }
                                "OfficeTab"  { $this.FindForm().MinimumSize = [Size]::new(550,400) }
                                "InfoTab"    { $this.FindForm().MinimumSize = [Size]::new(550,400) }
                            }
                        }
                    }
                }
            }
            Header = @{
                Control = "Label"
                ToolTip = "Doppelklicken zum Neustarten des Skripts (als Administrator)"

                Text        = "WINDOWS SETUP HELPER"
                Font        = Get-Font -Name "Consolas" -Size 22 -Style "Bold"
                Dock        = "Top"
                Height      = 50

                Add_DoubleClick = {
                    $this.FindForm().Dispose()
                    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs

                }

            }
            Footer = @{
                Control     = "TableLayoutPanel"
                Height      = 30
                Column      = @("50", "AutoSize", "50")
                Dock        = "Bottom"
                ForeColor   = Get-Color "Dark"
                BackColor   = Get-Color "Accent"
                Controls = [ordered]@{
                    About = @{
                        Control     = "Label"
                        Text        = "ABOUT"
                        Font        = Get-Font -Preset "FooterLink"
                        Anchor      = "Left"
                        AutoSize =    $true
                        
                        ToolTip     = "Informationen über das Skript"
                        Cursor      = Get-Cursor "Hand"
                        Add_Click = { Start-AboutUI }
                        Add_MouseEnter = { $this.Font = Get-Font -Preset "FooterLinkHover" }
                        Add_MouseLeave = { $this.Font = Get-Font -Preset "FooterLink" }
                    }
                    Version = @{
                        Control     = "Label"
                        Text        = "Version $($Manifest.ModuleVersion)"
                        Font        = Get-Font -Preset "FooterText"
                        AutoSize    = $true
                        Anchor      = "None"
                    }
                    PSConsole = @{
                        Control     = "Label"
                        Text        = "CONSOLE"
                        Font        = Get-Font -Preset "FooterLink"
                        Anchor      = "Right"
                        AutoSize    = $true
                        
                        ToolTip     = "PowerShell-Konsole anzeigen oder verstecken"
                        Cursor      = Get-Cursor "Hand"
                        Add_Click       = { if (Get-PSConsole) { Hide-PSConsole } else { Show-PSConsole } }
                        Add_MouseEnter  = { $this.Font = Get-Font -Preset "FooterLinkHover" }
                        Add_MouseLeave  = { $this.Font = Get-Font -Preset "FooterLink" }
                    }
                }
            }
        }
        Events      = @{
            FormClosed  = { [System.Environment]::Exit(0) }
            Load        = { $this.Text += if (Get-Administrator) { " – ADMINISTRATOR" } }

            Resize      = { 
                param($src, $e)
                $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
                $src.Location = [System.Drawing.Point]::new(
                    ($screen.Width - $src.Width) / 2,
                    ($screen.Height - $src.Height) / 2
                )

                (Get-Control $this "Header").Font = [Font]::new("Consolas", $(Resize-Form $this 22), [FontStyle]::Bold) 
            }

            Shown       = { 
                (Get-Control $this "Header").Font = [Font]::new("Consolas", $(Resize-Form $this 22), [FontStyle]::Bold)
                (Get-Control $this "TabControl").SelectedIndex = 1
            }
        }
    }
    WinGet      = @{
        Properties  = @{
            Text        = "WinGet"
            Icon        = "WinGet"
            ClientSize  = [Size]::new(600,300)
        }
        Controls    = @{
            PackagePanel = @{
                Control     = "Panel"
                Dock        = "Fill"
                Padding     = [Padding]::new(10,10,10,5)
                Controls    = [ordered]@{
                    TabControl = @{
                        Control     = "TabControl"
                        BackColor   = Get-Color "Dark"
                        ForeColor   = Get-Color "Accent"
                        Controls    = [ordered]@{
                            ManageTab = @{
                                Control     = "TabPage"
                                Text        = "Verwalten"
                                Controls    = @{
                                    InstalledList = @{
                                        Control = "ListBox"
                                        Dock    = "Fill"
                                        Add_SelectedIndexChanged = {
                                            $sidebarPanel   = $this.FindForm().Controls["SidebarPanel"]
                                            $packagePanel   = $this.FindForm().Controls["PackagePanel"]

                                            $sidebarPanel.Controls["UpdateAppButton"].Visible   = $this.SelectedItems.Count -gt 0
                                            $sidebarPanel.Controls["UninstallButton"].Visible   = $this.SelectedItems.Count -gt 0
                                            $packagePanel.Controls["SelectLabel"].Text          = & { 
                                                if ($this.Items.Count -eq $this.SelectedItems.Count) { return "Alle Abwählen" } else { return "Alle Auswählen" } 
                                            }
                                            
                                        }
                                    }
                                }
                            }
                            AddTab = @{
                                Control     = "TabPage"
                                Text        = "Hinzufügen"
                                Controls    = @{
                                    AddList = @{
                                        Control     = "CheckedListBox"
                                        Dock        = "Fill"

                                        Add_ItemCheck = {
                                            param($list, $item)
                                            $form = $this.FindForm()

                                            $count = $list.CheckedItems.Count
                                            if ($item.NewValue -eq [CheckState]::Checked) { $count++ } else { $count-- }

                                            $form.Controls["SidebarPanel"].Controls["InstallButton"].Visible    = $count -gt 0
                                            $form.Controls["PackagePanel"].Controls["SelectLabel"].Text         = & {
                                                if ($count -eq $list.Items.Count) { "Alle Abwählen" } else { "Alle Auswählen" }}
                                        }
                                    }
                                }
                            }
                        }
                        Add_SelectedIndexChanged = {
                            $selectedTab    = $this.SelectedTab
                            $sidebarPanel   = $this.FindForm().Controls["SidebarPanel"]
                            $addList        = $this.TabPages["AddTab"].Controls["AddList"]
                            $installedList  = $this.TabPages["ManageTab"].Controls["InstalledList"]

                            switch ($selectedTab.Name) {
                                <# MANAGE-TAB #>
                                "ManageTab"             {
                                    # Installierte Programme laden
                                    if ($installedList.Items.Count -eq 0) {
                                        foreach ($program in Get-WinGet -List){ 
                                            [void]$installedList.Items.Add($program)
                                        }
                                    }
                                }
                                { $_ -ne "ManageTab" }  { 
                                    # Buttons und Selektionen zurücksetzen, wenn Tab verlassen wird
                                    $installedList.ClearSelected()
                                    $sidebarPanel.Controls["UpdateAppButton"].Visible      = $false
                                    $sidebarPanel.Controls["UninstallButton"].Visible   = $false
                                }
                                <# ADD-TAB #>
                                "AddTab"                {
                                    # Verfügbaren Programme laden (nur beim ersten Mal)
                                    if ($addList.Items.Count -eq 0) {
                                        foreach ($program in Get-WinGet -SetupList) { 
                                            [void]$addList.Items.Add($program, $false)
                                        }
                                    }
                                }
                                { $_ -ne "AddTab" }     { 
                                    # Buttons und Selektionen zurücksetzen, wenn Tab verlassen wird
                                    $addList.ClearSelected()
                                    foreach ($index in $addList.CheckedIndices) { $addList.SetItemChecked($index, $false) }
                                    $sidebarPanel.Controls["InstallButton"].Visible  = $false
                                }
                            }
                        }
                    }
                    SelectLabel = @{
                        Control     = "Label"
                        Text        = "Alle Auswählen"
                        ForeColor   = Get-Color "Accent"
                        TextAlign   = "MiddleCenter"
                        Height      = 30
                        Font        = Get-Font -Preset "LabelButton"
                        Dock        = "Bottom"
                        Cursor      = [Cursors]::Hand
                        Add_Click = {
                            $tabControl     = $this.Parent.Controls["TabControl"]
                            $selectedTab    = $tabControl.SelectedTab
                            switch ($selectedTab.Name) {
                                "ManageTab" { 
                                    $installedList = $selectedTab.Controls["InstalledList"]
                                    if ($installedList.SelectedItems.Count -eq $installedList.Items.Count) { 
                                        [void]$installedList.ClearSelected()
                                    } else {
                                        for ($i = 0; $i -lt $installedList.Items.Count; $i++) { 
                                            $installedList.SetSelected($i, $true) 
                                        }
                                    }
                                }
                                "AddTab" { 
                                    $addList = $selectedTab.Controls["AddList"]
                                    $AllSelected = $addList.CheckedItems.Count -eq $addList.Items.Count
                                    for ($i = 0; $i -lt $addList.Items.Count; $i++) { 
                                        $addList.SetItemChecked($i, -not $AllSelected) 
                                        $addList.SetSelected($i, $false)
                                    }
                                }
                            }
                        }
                    }
                    ProcessLabel = @{
                        Control     = "Label"
                        Text        = "Starten..."
                        ForeColor   = Get-Color "Accent"
                        TextAlign   = "MiddleCenter"
                        Height      = 35
                        Font        = Get-Font -Name "Consolas" -Size 10 -Style "Italic"
                        Dock        = "Bottom"
                        Visible     = $false
                        Add_VisibleChanged = {
                            $this.Parent.Controls["SelectLabel"].Visible = -not $this.Visible
                        }
                    }
                }
            }
            SidebarPanel = @{
                Control     = "Panel"
                Dock        = "Right"
                ForeColor   = Get-Color "Dark"
                BackColor   = Get-Color "Accent"
                Padding     = [Padding]::new(10,5,0,0)
                Controls    = [ordered]@{
                    UninstallWinGetButton   = @{
                        Control     = "Button"
                        Text        = "WinGet entfernen"
                        Dock        = "Top"
                        Enabled     = $false
                        Add_Click = {                          
                            Get-WinGet -ShowText { param($msg, [switch]$Final) Update-Status -Label (Get-Control $this "ProcessLabel") -Message $msg -Delay 2 -Final:$Final } -Uninstall
                        }
                    }
                    InstallWinGetButton     = @{
                        Control     = "Button"
                        Text        = "WinGet hinzufügen"
                        Dock        = "Top"
                        Enabled     = $false
                        Add_Click = { 
                            $processLabel = $this.FindForm().Controls["PackagePanel"].Controls["ProcessLabel"]
                            Get-WinGet -ShowText { param($msg, [switch]$Final) Update-Status -Label $processLabel -Message $msg -Delay 2 -Final:$Final } -Install
                        }
                    }
                    WinGetVersionLabel      = @{
                        Control     = "Label"
                        Text        = "Version: "
                        TextAlign   = "MiddleCenter"
                        Dock        = "Top"
                        Height      = 20
                        Font        = Get-Font -Name "Consolas" -Size 10 -Style "Bold"
                    }
                    WinGetNameLabel         = @{
                        Control     = "Label"
                        Text        = "WinGet"
                        TextAlign   = "MiddleCenter"
                        Dock        = "Top"
                        Font        = Get-Font -Name "Cascadia Code" -Size 17 -Style "Bold"
                    }

                    UpdateAppButton = @{
                        Control     = "Button"
                        Text        = "Aktualisieren"
                        Visible     = $false
                        Dock        = "Bottom"
                        Add_Click   = { 
                            $ShowText = { param($msg, [switch]$Final) Update-Status -Label (Get-Control $this "ProcessLabel") -Message $msg -Delay 2 -Final:$Final }

                            & $ShowText "Updates werden installiert..."
                            $installedList = $this.FindForm().Controls["PackagePanel"].Controls["TabControl"].Controls["ManageTab"].Controls["InstalledList"]
                            foreach ($index in $installedList.SelectedIndices) { 
                                $appName = $installedList.Items[$index]
                                & $ShowText "Ausgewählte App: $($appName.Name)"
                                
                                & $ShowText "Name: $($appName.Name)"
                                & $ShowText "Id: $($appName.Id)"
                                & $ShowText "Version: $($appName.Version)"
                                Update-WinGetPackage -Id $appName.Id -ErrorAction SilentlyContinue
                                & $ShowText "Update abgeschlossen für: $($appName.Name)"
                                
                            }
                            & $ShowText "Alle Updates abgeschlossen." -Final
                        }
                    }
                    InstallButton = @{
                        Control = "Button"
                        Name    = "InstallButton"
                        Visible = $false
                        Text    = "Installieren"
                        Dock    = "Bottom"
                        
                        Add_Click = { 
                            $processLabel = $this.FindForm().Controls["PackagePanel"].Controls["ProcessLabel"]
                            $form = $this.FindForm()
                            $addList = $form.Controls["PackagePanel"].Controls["TabControl"].Controls["AddTab"].Controls["AddList"]
                            $apps = foreach ($index in $addList.CheckedIndices) { 
                                & $AppInfo.DebugText "Ausgewählte App: $($addList.Items[$index])"
                                $addList.Items[$index]
                            }
                            
                            & $AppInfo.DebugText "Der Typ von `$apps: $($apps.GetType().FullName)" 
                            Get-WinGet -ShowText { param($msg, [switch]$Final) Update-Status -Label $processLabel -Message $msg -Delay 2 -Final:$Final } -InstallApps $apps
                            
                            $addList.ClearSelected()
                            foreach ($index in $addList.CheckedIndices) { $addList.SetItemChecked($index, $false) }
                            }
                    }
                    UninstallButton = @{
                        Control = "Button"
                        Name    = "UninstallButton"
                        Visible = $false
                        Text    = "Deinstallieren"
                        Dock    = "Bottom"
                        Font    = [Font]::new("Tahoma", 8, [FontStyle]::Bold)
                        
                        Add_Click = { 
                            & $AppInfo.DebugText "'UninstallButton' geklickt. Bereite Deinstallation vor..."
                            $processLabel   = $this.FindForm().Controls["PackagePanel"].Controls["ProcessLabel"]
                            $installedList = $this.FindForm().Controls.Find("InstalledList", $true)[0]
                            $checkedList = $installedList.SelectedItems #| ForEach-Object { $_.Id }
                            
                            # Write-Host "Der Inhalt von `$checkedList: " $checkedList
                            Get-WinGet -ShowText { param($msg, [switch]$Final) Update-Status -Label $processLabel -Message $msg -Delay 2 -Final:$Final } -UninstallApps $checkedList
                            $installedList.SelectedItems.Clear() 
                        }
                    }
                }
            }
        }
        Events      = @{
            Load = { 
                $sidebarPanel   = $this.Controls["SidebarPanel"]

                & $AppInfo.DebugText "Überprüfe WinGet-Installation..."
                if (Get-WinGet) { 
                    & $AppInfo.DebugText "WinGet ist installiert. Aktiviere Deinstallations-Button."
                    $sidebarPanel.Controls["UninstallWinGetButton"].Enabled = $true 
                    $sidebarPanel.Controls["WinGetVersionLabel"].Text += Get-WinGet -Version
                } else { 
                    & $AppInfo.DebugText "WinGet ist nicht installiert. Aktiviere Installations-Button."
                    $sidebarPanel.Controls["InstallWinGetButton"].Enabled   = $true 
                    $sidebarPanel.Controls["WinGetVersionLabel"].Text += "Nicht installiert"
                }
            }
            Shown = { 
                $tabControl     = $this.Controls["PackagePanel"].Controls["TabControl"]
                $InstalledList  = $tabControl.Controls["ManageTab"].Controls["InstalledList"]
                
                # Installierte Programme laden
                & $AppInfo.DebugText "Lade installierte Programme..."
                foreach ($program in Get-WinGet -List) { 
                    [void]$InstalledList.Items.Add($program) 
                }
            }
        }
    }
}

Start-Form $FormConfig.Main
