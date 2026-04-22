using namespace System.Windows.Forms
using namespace System.Drawing
using namespace Console
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization
[Application]::EnableVisualStyles()


#Überprüfen, ob das Skript mit Administratorrechten ausgeführt wird
if ( -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')){
    Write-Host "Starte als Administrator neu..."
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    [System.Environment]::Exit(0)
}

$global:ErrorActionPreference = "SilentlyContinue"
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
$Manifest = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot "WindowsSetupHelper.psd1")
$global:AppInfo = @{
    Name        = "Windows Setup Helper"
    Version     = $Manifest.ModuleVersion
    Author      = $Manifest.Author
    Company     = $Manifest.CompanyName
    License     = "MIT License"
}
$global:AppConfig = @{
    IconPath    = "$PSScriptRoot\Assets\Icons"
    HideShell   = $false
}

Write-Information "Starte $($AppInfo.Name) v$($AppInfo.Version) by $($AppInfo.Author)"
$env:PSModulePath += ";$PSScriptRoot\Modules"


if ($AppConfig.HideShell) { Hide-PSConsole }
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
                            MainTab     = @{
                                Control     = "TabPage"
                                Text        = "System"
                                Controls    = [ordered]@{
                                    MainTable = @{
                                        Control     = "TableLayoutPanel"
                                        Dock        = "Fill"
                                        Padding     = [Padding]::new(10)
                                        Column      = @( "35", "50" )
                                        Row         = @( 35, 25, 25, 30, 30, 30, 30, 30, "AutoSize" )
                                        Controls    = [ordered]@{
                                            # Row 1 – Systeminformationen
                                            SystemLabel = @{
                                                ColumnSpan  = 2
                                                Control     = "Label"
                                                Text        = "Systeminformationen"
                                                Font        = Get-Font -Preset "TableTitle"
                                            }
                                            # Row 2 – Windows-Version
                                            WindowsVersionLabel = @{
                                                Control     = "Label"
                                                Text        = "Windows-Version:"
                                                Font        = Get-Font -Preset "TableLabel" 
                                                TextAlign   = "MiddleLeft"
                                            }
                                            WindowsVersionValue = @{
                                                Control     = "Label"
                                                Text        = $SystemInfo.ProductName
                                                Font        = Get-Font -Preset "TableText"
                                                TextAlign   = "MiddleLeft"
                                            }

                                            # Row 3 – Gerätename
                                            DeviceNameLabel = @{
                                                Control     = "Label"
                                                Text        = "Gerätename:"
                                                Font        = Get-Font -Preset "TableLabel"
                                                TextAlign   = "MiddleLeft"
                                            }
                                            DeviceNameValue = @{
                                                Control     = "Label"
                                                Text        = $($env:COMPUTERNAME)
                                                Font        = Get-Font -Preset "TableText"
                                                TextAlign   = "MiddleLeft"

                                                Cursor      = Get-Cursor "Hand"
                                                ToolTip     = "Gerätename ändern"
                                                Add_Click   = { Set-DeviceName }
                                                # Add_Click   = { Get-TextInputForm -Title "Gerätename ändern" -Label "Neuer Gerätename:" -DefaultValue $env:COMPUTERNAME }
                                            }

                                        }
                                    }
                                }
                            }
                            DebloatTab  = @{
                                Control     = "TabPage"
                                Text        = "Debloat"
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
                                                Add_Click       = { & (Join-Path $PSScriptRoot "Debloat/Uninstall-OneDrive.ps1") }
                                            }
                                            UninstallEdge = @{
                                                Control     = "Label"
                                                Text        = "Microsoft Edge entfernen"
                                                Font        = Get-Font -Preset "TableLink"
                                                Position    = 0,2
                                                Cursor      = Get-Cursor "Hand"

                                                Add_MouseEnter  = { $this.Font = Get-Font -Preset "TableLink" -Style @("Italic","Underline") }
                                                Add_MouseLeave  = { $this.Font = Get-Font -Preset "TableLink" -Style "Italic" }
                                                Add_Click       = { & (Join-Path $PSScriptRoot "Debloat/Uninstall-MicrosoftEdge.ps1") }
                                            }   
                                            # Column 2 – System aufräumen
                                            CleanerLabel = @{
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
                                                Add_Click   = { & (Join-Path $PSScriptRoot "Debloat/Remove-StartMenuIcons.ps1") }
                                            }

                                        }
                                    }
                                }
                            }
                            PackageTab  = @{
                                Control     = "TabPage"
                                Text        = "Programme"
                                Padding    = [Padding]::new(10,10,10,0)
                                Controls    = @{
                                    InstalledPackagesListBox = @{
                                        Control         = "ListView"
                                        Dock            = "Fill"
                                        Margin          = [Padding]::new(10)
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
                                        Control    = "TableLayoutPanel"
                                        Column      = @( "40", "30", "30" )
                                        Dock       = "Bottom"
                                        Height     = 40
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
                                        }
                                    }
                                }
                                Add_Enter = {
                                    $listView = Get-Control $this "InstalledPackagesListBox"
                                    if (-not $listView) { return }
                                    if (-not $listView.ContextMenuStrip) { 
                                        $listView.ContextMenuStrip = New-ContextMenu @{
                                            Items = @{
                                                Uninstall = @{
                                                    Text = "Deinstallieren"
                                                    Image = "uninstall.png"
                                                    Add_Click = {
                                                        $listView = $this.Owner.SourceControl
                                                        if (-not $listView) { return }

                                                        $programs = @($listView.SelectedItems | ForEach-Object { $_.Tag })
                                                        Uninstall-Program $programs
                                                        Update-InstalledProgramsList -ListView $listView
                                                    }
                                                }
                                            }
                                        }
                                    
                                    }
                                }
                            }
                            PowerTab = @{
                                Control     = "TabPage"
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
                                Control     = "TabPage"
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
                        }
                        Add_SelectedIndexChanged = {
                            param ($tabControl, $e)
                            $tabName = $tabControl.SelectedTab.Name
                            $header = Get-Control $this "Header"

                            $header.Text = switch ($tabName) {
                                "MainTab"       { $AppInfo.Name.ToUpper() }
                                "DebloatTab"    { "WINDOWS DEBLOATER" }
                                "PackageTab"    { "PROGRAMMVERWALTUNG" }
                                "PowerTab"      { "ENERGIEOPTIONEN" }
                                "OfficeTab"     { "OfficeR" }
                            }
                            if ($tabName -eq "PackageTab") {
                                $this.FindForm().MinimumSize = [Size]::new(1000,500)
                            }                                    
                        }
                        Add_Selecting = {
                            param ($tabControl, $e)
                            switch ($e.TabPage.Name) {
                                "MainTab"    { Import-Module SystemInfo }
                                "PackageTab" { Import-Module PackageManager }
                                "PowerTab"   { Import-Module PowerStatus }
                                "OfficeTab"  { Import-Module OfficeR }
                            }
                        }
                        Add_Selected = {
                            param ($tabControl, $e)
                            switch ($e.TabPage.Name) {
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
                # (Get-Control $this "TabControl").SelectedIndex = 2
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
