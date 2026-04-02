using namespace System.Windows.Forms
using namespace System.Drawing
using namespace Console
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization
[System.Windows.Forms.Application]::EnableVisualStyles()

#Überprüfen, ob das Skript mit Administratorrechten ausgeführt wird
if ( -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')){
    Write-Host "Starte als Administrator neu..."
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    [System.Environment]::Exit(0)
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

$global:AppInfo = @{
    Name        = "Windows Setup Helper"
    Version     = "0.9.10"
    Author      = "jonnilius"
    Company     = "BORINAS"
    License     = "MIT License"
}
$global:AppConfig = @{
    IconPath    = "$PSScriptRoot\Assets\Icons"
    HideShell   = $true
}

Write-Information "Starte $($AppInfo.Name) v$($AppInfo.Version) by $($AppInfo.Author)"
Write-Information "Lade Module..."
$env:PSModulePath += ";$PSScriptRoot\Modules"
Import-Module "$PSScriptRoot\Modules\Utils.psm1"
Import-Module "$PSScriptRoot\Modules\FormBuilder.psm1"
Import-Module "$PSScriptRoot\Modules\Chocolatey\Chocolatey.psm1"
Import-Module "$PSScriptRoot\Modules\PacketManager\PacketManager.psm1"

$script:ChocolateySearchToken = ""

if ($AppConfig.HideShell) { Hide-PSConsole }
<# FORM-DATA ############################################################################>
$FormConfig = @{
    Main        = @{
        Properties  = @{
            Icon        = Get-Icon "WindowsSetupHelper"
            ClientSize  = [Size]::new(420,370) # Breite, Höhe
            Padding     = [Padding]::new(10,0,10,0)
        }
        Controls    = [ordered]@{
            TabPanel = @{
                Control   = "Panel"
                Dock      = "Fill"
                Padding   = [Padding]::new(0)
                Controls  = @{
                    # ProcessLabel = @{
                    #     Name        = "ProcessLabel"
                    #     Control     = "Label"
                    #     Height      = 50
                    #     ForeColor   = Get-Color "Dark"
                    #     BackColor   = Get-Color "Accent"
                    #     Font        = Get-Font "Label" -Style "Italic"
                    #     Dock        = "Bottom"
                    #     TextAlign   = "MiddleCenter"
                    #     Text        = "Status: Bereit"
                    #     Visible     = $false

                    #     Add_VisibleChanged = {
                    #         $delta = if ($this.Visible) { 50 } else { -50 }
                    #         $form = $this.FindForm()
                            
                    #         Start-Sleep -Milliseconds 200
                    #         $form.ClientSize = [Size]::new($form.ClientSize.Width, $form.ClientSize.Height + $delta)
                    #     }
                    # }
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
                                                Font        = Get-Font "TableTitle"
                                                TextAlign   = "MiddleCenter"
                                            }
                                            # Row 2 – Windows-Version
                                            WindowsVersionLabel = @{
                                                Control     = "Label"
                                                Text        = "Windows-Version:"
                                                Font        = Get-Font "TableLabel" 
                                                TextAlign   = "MiddleLeft"
                                            }
                                            WindowsVersionValue = @{
                                                Control     = "Label"
                                                Text        = $SystemInfo.ProductName
                                                Font        = Get-Font "TableText"
                                                TextAlign   = "MiddleLeft"

                                                ToolTip     = "Version ändern"
                                            }

                                            # Row 3 – Gerätename
                                            DeviceNameLabel = @{
                                                Control     = "Label"
                                                Text        = "Gerätename:"
                                                Font        = Get-Font "TableLabel"
                                                TextAlign   = "MiddleLeft"
                                            }
                                            DeviceNameValue = @{
                                                Control     = "Label"
                                                Text        = $($env:COMPUTERNAME)
                                                Font        = Get-Font "TableText"
                                                TextAlign   = "MiddleLeft"

                                                Cursor      = Get-Cursor "Hand"
                                                ToolTip     = "Gerätename ändern"
                                                Add_Click   = { Start-Form $FormConfig.DeviceName }
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
                                                Font        = Get-Font "TableTitle"
                                                TextAlign   = "MiddleCenter"
                                                Position    = 0,0
                                            }
                                            UninstallOneDrive = @{
                                                Control     = "Label"
                                                Text        = "OneDrive entfernen"
                                                Font        = Get-Font "TableLink"
                                                Position    = 0,1
                                                Hover       = "Underline"
                                                Cursor      = Get-Cursor "Hand"
                                                
                                                Add_MouseEnter  = { $this.Font = Get-Font "TableLink" -Style @("Italic","Underline") }
                                                Add_MouseLeave  = { $this.Font = Get-Font "TableLink" -Style "Italic" }
                                                Add_Click       = { 
                                                    $processLabel = $this.FindForm().Controls.Find("ProcessLabel", $true)[0]
                                                    Remove-Item "OneDrive" { 
                                                        param([string]$msg, [switch]$final) 
                                                        Update-Status -Label $processLabel -Message $msg -Delay 1 -Final:$final 
                                                    } 
                                                }
                                            }
                                            UninstallEdge = @{
                                                Control     = "Label"
                                                Text        = "Microsoft Edge entfernen"
                                                Font        = Get-Font "TableLink"
                                                Position    = 0,2
                                                Cursor      = Get-Cursor "Hand"

                                                Add_MouseEnter  = { $this.Font = Get-Font "TableLink" -Style @("Italic","Underline") }
                                                Add_MouseLeave  = { $this.Font = Get-Font "TableLink" -Style "Italic" }
                                                Add_Click       = { 
                                                    $processLabel = $this.FindForm().Controls.Find("ProcessLabel", $true)[0]
                                                    Remove-Item "Edge" { 
                                                        param([string]$msg, [switch]$final) 
                                                        Update-Status -Label $processLabel -Message $msg -Delay 1 -Final:$final 
                                                    } 
                                                }
                                            }   
                                            # Column 2 – System aufräumen
                                            CleanerLabel = @{
                                                Control     = "Label"
                                                Text        = "System aufräumen"
                                                Font        = Get-Font "TableTitle"
                                                TextAlign   = "MiddleCenter"
                                                Position    = 1,0
                                            }
                                            HideStartMenuIcons = @{
                                                Control     = "Button"
                                                Text        = "Startmenü aufräumen"
                                                Font        = Get-Font "TableButton"
                                                Position    = 1,1
                                                Margin      = [Padding]::new(20,0,20,0)
                                                Add_Click   = { Remove-StartMenuIcons $this }
                                            }

                                        }
                                    }
                                }
                            }
                            PackageTab  = @{
                                Control     = "TabPage"
                                Text        = "Programme"
                                Controls    = @{
                                    PaketManagerTable = @{
                                        Control    = "TableLayoutPanel"
                                        Dock       = "Bottom"
                                        Column      = @( "50", "50" )
                                        Row         = @( 30, 25 )
                                        Controls    = @{
                                            PaketManagerLabel = @{
                                                ColumnSpan  = 2
                                                Position    = 0,1
                                                Control     = "Label"
                                                Text        = "Paket-Manager"
                                                Font        = Get-Font "Subtitle"
                                                ForeColor   = Get-Color "Accent"
                                                Dock        = "Bottom"
                                                TextAlign   = "MiddleCenter"
                                            }
                                            ChocolateyButton = @{
                                                Position    = 0,2
                                                Control     = "Button"
                                                Text        = "Chocolatey Software"
                                                Font        = Get-Font "Button"
                                                Dock        = "Fill"
                                                Margin      = [Padding]::new(10)
                                                Add_Click   = { Start-Form $FormConfig.Chocolatey }
                                            }
                                            WingetButton = @{
                                                Position    = 1,2
                                                Control     = "Button"
                                                Text        = "WinGet"
                                                Font        = Get-Font "Button"
                                                Dock        = "Fill"
                                                Margin      = [Padding]::new(10)
                                                Add_Click   = { Start-Form $FormConfig.Winget }
                                            }
                                        }
                                    }
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
                                                Font        = Get-Font "TableTitle"
                                                TextAlign   = "MiddleCenter"
                                                Position    = 0,0
                                            }
                                            UninstallOneDrive = @{
                                                Control     = "Label"
                                                Text        = "OneDrive entfernen"
                                                Font        = Get-Font "TableLink"
                                                Position    = 0,1
                                                Hover       = "Underline"
                                                Cursor      = Get-Cursor "Hand"
                                                
                                                Add_MouseEnter  = { $this.Font = Get-Font "TableLink" -Style @("Italic","Underline") }
                                                Add_MouseLeave  = { $this.Font = Get-Font "TableLink" -Style "Italic" }
                                                Add_Click       = { 
                                                    $processLabel = $this.FindForm().Controls.Find("ProcessLabel", $true)[0]
                                                    Remove-Item "OneDrive" { 
                                                        param([string]$msg, [switch]$final) 
                                                        Update-Status -Label $processLabel -Message $msg -Delay 1 -Final:$final 
                                                    } 
                                                }
                                            }
                                            UninstallEdge = @{
                                                Control     = "Label"
                                                Text        = "Microsoft Edge entfernen"
                                                Font        = Get-Font "TableLink"
                                                Position    = 0,2
                                                Cursor      = Get-Cursor "Hand"

                                                Add_MouseEnter  = { $this.Font = Get-Font "TableLink" -Style @("Italic","Underline") }
                                                Add_MouseLeave  = { $this.Font = Get-Font "TableLink" -Style "Italic" }
                                                Add_Click       = { 
                                                    $processLabel = $this.FindForm().Controls.Find("ProcessLabel", $true)[0]
                                                    Remove-Item "Edge" { 
                                                        param([string]$msg, [switch]$final) 
                                                        Update-Status -Label $processLabel -Message $msg -Delay 1 -Final:$final 
                                                    } 
                                                }
                                            }   
                                            # Column 2 – System aufräumen
                                            CleanerLabel = @{
                                                Control     = "Label"
                                                Text        = "System aufräumen"
                                                Font        = Get-Font "TableTitle"
                                                TextAlign   = "MiddleCenter"
                                                Position    = 1,0
                                            }
                                            HideStartMenuIcons = @{
                                                Control     = "Button"
                                                Text        = "Startmenü aufräumen"
                                                Font        = Get-Font "TableButton"
                                                Position    = 1,1
                                                Margin      = [Padding]::new(20,0,20,0)
                                                Add_Click   = { Remove-StartMenuIcons $this }
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
                                        Column      = @( "70", 80, 60 )
                                        Row         = @( 35, 30, 30, 30, 35, 30, 30, 30, 30 )
                                        Controls    = [ordered]@{
                                            # Row 1 – Im Netzbetrieb
                                            PowerLabelDC = @{
                                                # Position    = 0,0
                                                ColumnSpan  = 3
                                                Control     = "Label"
                                                Text        = "Im Netzbetrieb"
                                                Font        = Get-Font "TableTitle"
                                                # TextAlign   = "TopCenter"
                                            }
                                            # Row 2 – Im Netzbetrieb (Energiesparmodus)
                                            StandbyLabelAC = @{
                                                # Position    = 0,1
                                                Control     = "Label"
                                                Text        = "Energiesparmodus:"
                                                Font        = Get-Font "TableLabel"
                                                TextAlign   = "MiddleRight"
                                            }
                                            StandbyValueAC = @{
                                                # Position    = 1,1
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "AC" "Standby" -TextOutput
                                                Font        = Get-Font "TableLink"
                                            }
                                            StandbyButtonAC = @{
                                                # Position    = 2,1
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font "TableButton"
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
                                                Font        = Get-Font "TableLabel"
                                                TextAlign   = "MiddleRight"
                                            }
                                            HibernateValueAC = @{
                                                # Position    = 1,2
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "AC" "Hibernate" -TextOutput
                                                Font        = Get-Font "TableLink"
                                            }
                                            HibernateButtonAC = @{
                                                # Position    = 2,2
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font "TableButton"
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
                                                Font        = Get-Font "TableLabel"
                                                TextAlign   = "MiddleRight"
                                            }
                                            MonitorValueAC = @{
                                                # Position    = 1,3
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "AC" "Monitor" -TextOutput
                                                Font        = Get-Font "TableLink"
                                            }
                                            MonitorButtonAC = @{
                                                # Position    = 2,3
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font "TableButton"
                                                Add_Click   = { 
                                                    Update-PowerStatus -PowerScheme "AC" -StatusType "Monitor"
                                                    $this.FindForm().Controls.Find("MonitorValueAC", $true)[0].Text = Get-PowerStatus "AC" "Monitor" -TextOutput
                                                 }
                                            }
                                            
                                            # Row 5 – Im Akkubetrieb
                                            BatteryLabelDC = @{
                                                ColumnSpan  = 3
                                                # Position    = 0,4
                                                Control     = "Label"
                                                Text        = "Im Akkubetrieb"
                                                Font        =  Get-Font "TableTitle"
                                                TextAlign   = "TopCenter"
                                            }
                                            # Row 6 – Im Akkubetrieb (Energiesparmodus)
                                            StandbyLabelDC = @{
                                                # Position    = 0,5
                                                Control     = "Label"
                                                Text        = "Energiesparmodus:"
                                                Font        = Get-Font "TableLabel"
                                                TextAlign   = "MiddleRight"
                                            }
                                            StandbyValueDC = @{
                                                # Position    = 1,5
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "DC" "Standby" -TextOutput
                                                Font        = Get-Font "TableLink"
                                            }
                                            StandbyButtonDC = @{
                                                # Position    = 2,5
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font "TableButton"
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
                                                Font        = Get-Font "TableLabel"
                                                TextAlign   = "MiddleRight"
                                            }
                                            HibernateValueDC = @{
                                                # Position    = 1,6
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "DC" "Hibernate" -TextOutput
                                                Font        = Get-Font "TableLink"
                                            }
                                            HibernateButtonDC = @{
                                                # Position    = 2,6
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font "TableButton"
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
                                                Font        = Get-Font "TableLabel"
                                                TextAlign   = "MiddleRight"
                                            }
                                            MonitorValueDC = @{
                                                # Position    = 1,7
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "DC" "Monitor" -TextOutput
                                                Font        = Get-Font "TableLink"
                                            }
                                            MonitorButtonDC = @{
                                                # Position    = 2,7
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font "TableButton"
                                                Add_Click   = { 
                                                    Update-PowerStatus -PowerScheme "DC" -StatusType "Monitor"
                                                    $this.FindForm().Controls.Find("MonitorValueDC", $true)[0].Text = Get-PowerStatus "DC" "Monitor" -TextOutput
                                                }
                                            }
                                            # Row 9 – Energiesparmodus deaktivieren
                                            DisableSleep = @{
                                                ColumnSpan  = 3
                                                # Position    = 0,8
                                                Control     = "Button"
                                                Text        = "Energiesparmodus deaktivieren"
                                                Font        = Get-Font "TableButton"
                                                Visible     = $false
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
                                                    if ($this.Visible) { $this.FindForm().MinimumSize = [Size]::new(350,450) } else { $this.FindForm().MinimumSize = [Size]::new(350,420) }
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
                        }
                        Add_SelectedIndexChanged = {
                            # Beim Wechseln der Registerkarte den Titel anpassen, um den aktuellen Bereich anzuzeigen
                            switch ($this.SelectedTab.Name) {
                                "MainTab"       { (Get-Control $this "Header").Text = $AppInfo.Name.ToUpper() }
                                "DebloatTab"    { (Get-Control $this "Header").Text = "WINDOWS DEBLOATER" }
                                "PackageTab"    { (Get-Control $this "Header").Text = "PROGRAMMVERWALTUNG" }
                                "PowerTab"      { (Get-Control $this "Header").Text = "ENERGIEOPTIONEN" 
                                
                                    $this.FindForm().MinimumSize = [Size]::new(350,420)
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
                # TextAlign   = "MiddleCenter"

                Add_DoubleClick = {
                    $this.FindForm().Dispose()
                    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
                    
                }

            }
            Footer = @{
                Control = "TableLayoutPanel"

                Height      = 30
                Column      = @(150, "100", 150)
                Dock        = "Bottom"
                ForeColor   = Get-Color "Dark"
                BackColor   = Get-Color "Accent"

                Controls = [ordered]@{
                    About = @{
                        Control = "Label"
                        Cursor  = Get-Cursor "Hand"
                        ToolTip = "Informationen über das Skript"

                        Text        = "ABOUT"
                        Font        = Get-Font -Name "Consolas" -Size 8 -Style "Underline"
                        Anchor      = "Left"
                        TextAlign   = "MiddleLeft"

                        Add_Click = { Start-Form $FormConfig.About }
                    }
                    Version = @{
                        Control = "Label"

                        Text        = "Version $($AppInfo.Version)"
                        Font        = Get-Font -Name "Consolas" -Size 8 -Style "Italic"
                        Anchor      = "None"
                        TextAlign   = "MiddleCenter"
                    }
                    PSConsole = @{
                        Control = "Label"
                        Cursor  = Get-Cursor "Hand"
                        ToolTip = "PowerShell-Konsole anzeigen oder verstecken"
                        
                        Text        = if ($AppConfig.HideShell) { "KONSOLE ANZEIGEN" } else { "KONSOLE VERSTECKEN" }
                        Font        = Get-Font -Name "Consolas" -Size 8 -Style "Underline"
                        Anchor      = "Right"
                        TextAlign   = "MiddleRight"

                        Add_Click = {
                            $this.Text = if ($this.Text -eq "KONSOLE ANZEIGEN") { 
                                Show-PSConsole
                                "KONSOLE VERSTECKEN" 
                            } else { 
                                Hide-PSConsole
                                "KONSOLE ANZEIGEN" 
                            }
                        }
                    }
                }
            }
        }
        Events      = @{
            FormClosed  = { 
                # Beim Schließen vom Form die Konsole ebenfalls schließen, um sicherzustellen, dass keine Prozesse offen bleiben
                [System.Environment]::Exit(0) 
            }
            Load        = { 
                # Beim Laden des Forms den Titel anpassen, um anzuzeigen, ob das Skript mit Administratorrechten läuft
                $this.Text += if (Get-Administrator) { " – Administrator".ToUpper() }

                # Beim Laden des Forms den Text der PSConsole-Schaltfläche basierend auf der aktuellen Einstellung anpassen
                (Get-Control $this "PSConsole").Text = if ($AppConfig.HideShell) { "KONSOLE ANZEIGEN" } else { "KONSOLE VERSTECKEN" }
            }
            Resize      = { 
                # Beim Ändern der Fenstergröße die Schriftgröße der Überschrift dynamisch anpassen, damit sie immer gut lesbar ist
                (Get-Control $this "Header").Font = [Font]::new("Consolas", $(Resize-Form $this 22), [FontStyle]::Bold)
            }
            Shown       = { 
                # Beim ersten Anzeigen des Forms die Überschrift anpassen und die erste Registerkarte auswählen
                (Get-Control $this "Header").Font = [Font]::new("Consolas", $(Resize-Form $this 22), [FontStyle]::Bold)
            }
        }
    }
    About       = @{
        Properties  = @{
            Text            = "About"
            Icon            = Get-Icon "About"
            ClientSize      = [Size]::new(350,400)
            FormBorderStyle = "FixedDialog"
            KeyPreview      = $true
        }
        Controls    = @{
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
                                ForeColor = Get-Color "Accent"
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
        Events      = @{
            KeyDown = { if ($_.KeyCode -eq "Escape") { $this.Close() } }
        }
    }
    Chocolatey  = @{
        Properties  = @{
            Text        = "Chocolatey"
            ClientSize  = [Size]::new(600,350)
            Icon        = Get-Icon "Chocolatey"
        }
        Controls    = @{
            PackagePanel = @{
                Control     = "Panel"
                Dock        = "Fill"
                Padding     = [Padding]::new(5)
                Controls    = [ordered]@{
                    TabControl = @{
                        Control     = "TabControl"
                        Controls    = [ordered]@{
                            SearchTab = @{
                                Control     = "TabPage"
                                Text        = "Suchen"
                                Padding    = [Padding]::new(10)
                                Controls    = [ordered]@{
                                    TabList = @{
                                        Control         = "ListBox"
                                        Dock            = "Fill"
                                        SelectionMode   = "MultiExtended"
                                        Visible         = $false
                                        Add_SelectedIndexChanged = {
                                            param($src, $e)
                                            $listbox = $src
                                            $selectedItems    = $listbox.SelectedItems

                                            # Schutz gegen unbeabsichtigte Auslösung während der Aktualisierung der Liste
                                            if ($listbox.Tag -is [hashtable] -and $listbox.Tag.SuppressSelectionChanged) { return }

                                            # Sidebar-Steuerelemente abrufen
                                            (Get-Control $this "InstallButton").Visible = $selectedItems.Count -gt 0
                                            $searchInfo       = (Get-Control $this "SearchInfo")
                                            $searchHeader     = $searchInfo.Controls["SearchHeader"]
                                            $processLabel     = $searchInfo.Controls["ProcessLabel"]
                                            $searchInfoLabel  = $searchInfo.Controls["SearchInfoLabel"]
                                            
                                            # Kein Paket ausgewählt
                                            if ($selectedItems.Count -eq 0) {


                                                $searchHeader.Text    = "Wähle ein Paket aus, um Details anzuzeigen."
                                                $processLabel.Visible = $false
                                                Set-SearchInfoLabelText -Label $searchInfoLabel
                                            } elseif ($selectedItems.Count -eq 1) {
                                                $selectedPackage = $selectedItems[0]

                                                $searchHeader.Text    = $selectedPackage.DisplayName
                                                $processLabel.Text    = "Lade Details..."
                                                $processLabel.Visible = $true
                                                Set-SearchInfoLabelText -Label $searchInfoLabel

                                                $details = Get-CachedApplicationDetails -Name $selectedPackage.Id -Manager "Chocolatey" -SearchDurationMs 6000 -FallbackVersion $selectedPackage.Version
                                                if ($details) {
                                                    $searchHeader.Text = if (-not [string]::IsNullOrWhiteSpace($details.Title)) {
                                                        $details.Title
                                                    } else {
                                                        $selectedPackage.DisplayName
                                                    }

                                                    $lines = @()
                                                    $meta = @(
                                                        "Id: $($details.Id)",
                                                        "Version: $($details.Version)"
                                                    )
                                                    if (-not [string]::IsNullOrWhiteSpace($details.Published)) {
                                                        $meta += "Veröffentlicht: $($details.Published)"
                                                    }

                                                    if (-not [string]::IsNullOrWhiteSpace($details.Authors))      { $lines += "Autor(en): $($details.Authors)" }
                                                    if (-not [string]::IsNullOrWhiteSpace($details.Tags))         { $lines += "Tags: $($details.Tags)" }
                                                    if (-not [string]::IsNullOrWhiteSpace($details.Summary))      { $lines += "Kurzbeschreibung: $($details.Summary)" }
                                                    if (-not [string]::IsNullOrWhiteSpace($details.SoftwareSite)) { $lines += "Website: $($details.SoftwareSite)" }

                                                    $processLabel.Text = ($meta -join " | ")
                                                    $processLabel.Visible = $true
                                                    Set-SearchInfoLabelText -Label $searchInfoLabel -Lines $lines -Description $details.Description

                                                    $details.DisplayName = Get-ApplicationDisplayName -Package $details
                                                    if ($selectedPackage.DisplayName -ne $details.DisplayName) {
                                                        Update-ChocolateySearchListItem -ListBox $src -Package $details
                                                    }
                                                } else {
                                                    $processLabel.Text = "Details konnten nicht geladen werden."
                                                }
                                            } else {
                                                $searchHeader.Text    = "$($selectedItems.Count) Pakete ausgewählt"
                                                $processLabel.Visible = $false
                                                Set-SearchInfoLabelText -Label $searchInfoLabel -Lines @("Mehrfachauswahl aktiv. Wähle ein Paket für Details.")
                                            }
                                        }
                                    }
                                    Space = @{
                                        Control = "Panel"
                                        Height = 15
                                        Dock = "Top"
                                        BackColor = Get-Color "Transparent"
                                    }
                                    SearchBox = @{
                                        Control         = "TextBox"
                                        Dock            = "Top"
                                        Font            = Get-Font "TextBox"
                                        BackColor       = Get-Color "Accent"
                                        ForeColor       = Get-Color "Dark"
                                        BorderStyle     = "None"
                                        Add_TextChanged = {
                                            param($src, $e)
                                            $query = $src.Text.Trim()

                                            $tabLabel   = $src.Parent.Controls["TabLabel"]
                                            $tabList    = $src.Parent.Controls["TabList"]
                                            $header     = $src.Parent.Controls["SearchHeader"]
                                            
                                            if (-not ($src.Tag -is [hashtable])) { $src.Tag = @{} }

                                            Stop-ChocolateySearchTitleEnrichment -SearchBox $src

                                            if ($src.Tag.ContainsKey("SearchTimer") -and $src.Tag.SearchTimer) {
                                                $src.Tag.SearchTimer.Stop()
                                                $src.Tag.SearchTimer.Dispose()
                                                $src.Tag.SearchTimer = $null
                                            }

                                            # Wenn die Suchanfrage leer ist, zeige die Anweisungen an und verstecke die Ergebnisliste
                                            if ([string]::IsNullOrWhiteSpace($query)) {
                                                $script:ChocolateySearchToken = [guid]::NewGuid().ToString("N")
                                                $header.Visible = $true
                                                $tabList.Items.Clear()
                                                $tabList.Visible = $false
                                                $tabLabel.Text = "Gib den Namen eines Chocolatey-Paketes ein, um nach verfügbaren Paketen zu suchen. `n(mindestens 3 Zeichen eingeben)"
                                                $tabLabel.Visible = $true
                                                return
                                            }

                                            # Wenn die Suchanfrage weniger als 3 Zeichen enthält, zeige eine Warnung an und verstecke die Ergebnisliste
                                            if ($query.Length -lt 3) {
                                                $script:ChocolateySearchToken = [guid]::NewGuid().ToString("N")
                                                $header.Visible = $false
                                                $tabList.Items.Clear()
                                                $tabList.Visible = $false
                                                $tabLabel.Text = "Bitte mindestens 3 Zeichen eingeben."
                                                $tabLabel.Visible = $true
                                                return
                                            }

                                            # Generiere ein neues Such-Token, um veraltete Suchvorgänge zu invalidieren
                                            $script:ChocolateySearchToken = [guid]::NewGuid().ToString("N")
                                            $token = $script:ChocolateySearchToken

                                            $tabLabel.Text      = "Suche nach '$($query)'... "
                                            $tabLabel.Visible   = $true
                                            $tabList.Visible    = $false
                                            $header.Visible     = $false

                                            # Suchzeitgeber erstellen, um die Suche um 300ms zu verzögern (debouncing)
                                            $timer = [System.Windows.Forms.Timer]::new()
                                            $timer.Interval = 300
                                            $timer.Tag = @{
                                                SearchBox = $src
                                                Query = $query
                                                TabLabel = $tabLabel
                                                TabList = $tabList
                                                Token = $token
                                            }

                                            # Ereignis-Handler für den Timer-Tick definieren
                                            $timer.Add_Tick({
                                                $this.Stop()

                                                $state = $this.Tag
                                                $this.Dispose()

                                                if (-not $state -or $state.SearchBox.IsDisposed) { return }
                                                if (-not ($state.SearchBox.Tag -is [hashtable])) { return }
                                                $state.SearchBox.Tag.SearchTimer = $null

                                                if ($state.Token -ne $script:ChocolateySearchToken) { return }

                                                $results = Search-Application -Query $state.Query -Manager "Chocolatey" -SearchToken $state.Token -SearchBox $state.SearchBox -SearchDurationMs 12000

                                                if ($state.Token -ne $script:ChocolateySearchToken) { return }
                                                if ($state.SearchBox.Text.Trim() -ne $state.Query) { return }

                                                $state.TabList.Items.Clear()
                                                if ($results.Count -gt 0) {
                                                    [void]$state.TabList.Items.AddRange($results)
                                                    $state.TabList.DisplayMember = "DisplayName"
                                                    $state.TabList.Visible = $true
                                                    $state.TabLabel.Visible = $false
                                                    Start-ChocolateySearchTitleEnrichment -SearchBox $state.SearchBox -ListBox $state.TabList -Results $results -Token $state.Token
                                                } else {
                                                    $state.TabList.Visible = $false
                                                    $state.TabLabel.Text = "Keine Pakete gefunden."
                                                    $state.TabLabel.Visible = $true
                                                }
                                            })

                                            $src.Tag.SearchTimer = $timer
                                            $timer.Start()
                                        }
                                    }
                                    SearchHeader = @{
                                        Control     = "Label"
                                        Text        = "Package suchen"
                                        Dock        = "Top"
                                        Font        = Get-Font "SearchHeader"
                                        ForeColor   = Get-Color "Accent"
                                        Height      = 100
                                    }
                                    TabLabel = @{
                                        Control     = "Label"
                                        Text        = "Gib den Namen eines Chocolatey-Paketes ein, um nach verfügbaren Paketen zu suchen. `n(mindestens 3 Zeichen eingeben)"
                                        Dock        = "Bottom"
                                        Font        = Get-Font "LabelItalic"
                                        TextAlign   = "MiddleCenter"
                                        Height      = 50
                                    }
                                }
                            }
                            SuggestedTab = @{
                                Control     = "TabPage"
                                Text        = "Hinzufügen"
                                Controls    = @{
                                    TabLabel = @{
                                        Control = "Label"
                                        Text    = "Lade vorgeschlagene Chocolatey-Pakete..."
                                        Dock    = "Fill"
                                        Font    = Get-Font "LabelItalic"
                                    }
                                    TabList = @{
                                        Control = "CheckedListBox"
                                        Dock    = "Fill"
                                        Visible = $false
                                        Add_ItemCheck = {
                                            param($src, $e)
                                            $count = $src.CheckedItems.Count
                                            if ($e.NewValue -eq [CheckState]::Checked) { $count++ } else { $count-- }

                                            (Get-Control $this "InstallButton").Visible = $count -gt 0
                                            (Get-Control $this "SelectLabel").Text      = if ($count -eq $this.Items.Count) { "Alle Abwählen" } else { "Alle Auswählen" }
                                        }
                                    }
                                }
                            }
                            PackagesTab = @{
                                Control     = "TabPage"
                                Text        = "Verwalten"
                                Controls    = @{
                                    TabLabel = @{
                                        Control = "Label"
                                        Text    = "Lade installierte Chocolatey-Pakete..."
                                        Dock    = "Fill"
                                        Font    = Get-Font "LabelItalic"
                                    }
                                    TabList = @{
                                        Control     = "ListBox"
                                        Dock        = "Fill"
                                        Visible     = $false
                                        Add_SelectedIndexChanged = {
                                            (Get-Control $this "UpdateButton").Visible      = $this.SelectedItems.Count -gt 0
                                            (Get-Control $this "UninstallButton").Visible   = $this.SelectedItems.Count -gt 0
                                            (Get-Control $this "SelectLabel").Text      = if ($this.SelectedItems.Count -eq $this.Items.Count) { "Alle Abwählen" } else { "Alle Auswählen" }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Add_SelectedIndexChanged = {
                            param($src, $e)
                            $tabName     = $src.SelectedTab.Name

                            # Hole die Steuerelemente für das aktuelle Tab
                            $selectLabel = (Get-Control $this "SelectLabel")
                            $tabLabel    = $src.SelectedTab.Controls["TabLabel"]
                            $tabList     = $src.SelectedTab.Controls["TabList"]
                            
                            # Buttons ausblenden, bis eine Auswahl getroffen wird
                            (Get-Control $this "UpdateButton").Visible      = $false
                            (Get-Control $this "UninstallButton").Visible   = $false
                            (Get-Control $this "InstallButton").Visible     = $false
                            $tabList.Items.Clear()

                            # Lade die entsprechenden Daten, wenn der Tab gewechselt wird
                            switch ($tabName) {
                                "SearchTab" {
                                    $selectLabel.Visible = $false
                                    return
                                }
                                "PackagesTab" {
                                    $tabLabel.Text = "Lade installierte Chocolatey-Pakete..."
                                    [void]$tabList.Items.AddRange((Get-Chocolatey -List))
                                    break
                                }
                                "SuggestedTab" {
                                    $tabLabel.Text = "Lade vorgeschlagene Chocolatey-Pakete..."
                                    [void]$tabList.Items.AddRange((Get-Chocolatey -Suggested))
                                    break
                                }
                            }
                            
                            # Sichtbarkeit der Steuerelemente anpassen
                            $tabLabel.Visible    = $false
                            $tabList.Visible     = $true
                            $selectLabel.Visible = $true
                            
                        }
                        Add_Deselected = {
                            param($src, $e)

                            # Leere die Listen, wenn der Tab verlassen wird
                            $tabList    = $e.TabPage.Controls["TabList"]
                            $listType   = $tabList.GetType().Name
                            $tabList.ClearSelected()

                            if ($listType -eq "CheckedListBox") {
                                foreach ($index in $tabList.CheckedIndices) { 
                                    $tabList.SetItemChecked($index, $false) 
                                }
                            }

                            # Sichtbarkeit der Steuerelemente zurücksetzen
                            (Get-Control $this "UpdateButton").Visible      = $false
                            (Get-Control $this "UninstallButton").Visible   = $false
                            (Get-Control $this "InstallButton").Visible     = $false
                        }

                    }
                    SelectLabel = @{
                        Control     = "Label"
                        Text        = "Alle auswählen"
                        Height      = 30
                        Font        = Get-Font "LabelButton"
                        Dock        = "Bottom"
                        Cursor      = Get-Cursor "Hand"
                        Visible     = $false
                        Add_Click   = {
                            $selectedTab = $this.Parent.Controls["TabControl"].SelectedTab
                            $tabList     = $selectedTab.Controls["TabList"]
                            $listCount   = $tabList.Items.Count
                            
                            switch ($tabList.GetType().Name) {
                                 "ListBox" { 
                                    if ($tabList.SelectedItems.Count -eq $listCount) {
                                        $tabList.ClearSelected()
                                    } else {
                                        for ($i = 0; $i -lt $listCount; $i++) { $tabList.SetSelected($i, $true) }
                                    }
                                }
                                 "CheckedListBox" { 
                                    if ($tabList.CheckedItems.Count -eq $listCount) {
                                        $tabList.ClearSelected()
                                        for ($i = 0; $i -lt $listCount; $i++) { $tabList.SetItemChecked($i, $false) }
                                    } else {
                                        for ($i = 0; $i -lt $listCount; $i++) { $tabList.SetItemChecked($i, $true) }
                                    }
                                }
                            }
                        }
                    }
                    ProcessLabel = @{
                        Control             = "Label"
                        Text                = "Starte..."
                        Height              = 30
                        Font                = Get-Font "LabelItalic"
                        Dock                = "Bottom"
                        Visible             = $false
                        Add_VisibleChanged  = {
                            if ($this.Visible) { (Get-Control $this "SelectLabel").Visible = $false }
                                else { (Get-Control $this "SelectLabel").Visible = $true }
                        }
                    }
                }
            }
            SidebarPanel = @{
                Control     = "Panel"
                Name        = "SidebarPanel"
                Dock        = "Right"
                ForeColor   = Get-Color "Dark"
                BackColor   = Get-Color "Accent"
                Padding     = [Padding]::new(10,5,0,0)
                Controls    = [ordered]@{

                    SearchInfo = @{
                        Control     = "FlowLayoutPanel"
                        Dock        = "Fill"
                        FlowDirection= "TopDown"
                        WrapContents = $false
                        ForeColor           = Get-Color "Dark"
                        BackColor   = Get-Color "Accent"
                        # Visible     = $false
                        Controls    = [ordered]@{
                            SearchHeader = @{
                                Control     = "Label"
                                Text        = "Wähle ein Paket aus, um Details anzuzeigen."
                                Dock        = "Top"
                                Font        = Get-Font "Label" -Size 13 -Style "Bold"
                                Height      = 60
                            }
                            ProcessLabel = @{
                                Control             = "Label"
                                Text                = "Starte..."
                                Height              = 30
                                Font                = Get-Font "LabelItalic"
                                Dock                = "Top"
                                Visible             = $false
                            }
                            SearchInfoLabel = @{
                                Control     = "Label"
                                Text        = ""
                                Dock        = "Top"
                                Font        = Get-Font "LabelItalic"
                                AutoSize    = $true
                                Cursor      = [Cursors]::Default
                                ToolTip     = "Klicken, um lange Beschreibungen ein- oder auszuklappen."
                                Add_Click   = {
                                    if ($this.Tag -is [hashtable] -and $this.Tag.ToggleEnabled) {
                                        $this.Tag.Expanded = -not $this.Tag.Expanded
                                        $this.Text = if ($this.Tag.Expanded) { $this.Tag.ExpandedText } else { $this.Tag.CollapsedText }
                                    }
                                }
                            }
                        }
                    }
                    # Chocolatey deinstallieren Button
                    UninstallChocoButton = @{
                        Control     = "Button"
                        Text        = "Chocolatey entfernen"
                        Dock        = "Top"
                        Visible     = $false
                        Font        = Get-Font "SidebarButton"
                        Add_Click   = { 
                            Uninstall-Chocolatey { param($msg, [switch]$Final) Update-Status -Label (Get-ProcessLabel $this) -Message $msg -Delay 2 -Final:$Final }
                        }
                    }
                    # Chocolatey installieren Button
                    InstallChocoButton = @{
                        Control     = "Button"
                        Text        = "Chocolatey hinzufügen"
                        Dock        = "Top"
                        Visible     = $false
                        Font        = Get-Font "SidebarButton"
                        Add_Click   = { 
                            Install-Chocolatey { param($msg, [switch]$Final) Update-Status -Label (Get-ProcessLabel $this) -Message $msg -Delay 2 -Final:$Final }
                        }
                    }
                    # Anzeige der Chocolatey-Version
                    VersionLabel = @{
                        Control     = "Label"
                        TextAlign   = "TopCenter"
                        Dock        = "Top"
                        Height      = 25
                        Font        = Get-Font "SidebarLabel"
                        Text        = "Version: "
                    }
                    # Chocolatey-Titel
                    NameLabel = @{
                        Control     = "Label"
                        Text        = "Chocolatey"
                        TextAlign   = "MiddleCenter"
                        Dock        = "Top"
                        Height      = 35
                        Font        = Get-Font "HeaderLow"
                    }

                    # Pakete aktualisieren Button
                    UpdateButton = @{
                        Control     = "Button"
                        Text        = "Aktualisieren"
                        Visible     = $false
                        Dock        = "Bottom"
                        Font        = Get-Font "SidebarButton"
                        Add_Click   = { 
                            $NewStatus          = { param($msg, [switch]$Final) Update-Status -Label (Get-ProcessLabel $this) -Message $msg -Delay 2 -Final:$Final }
                            $selectedTab        = (Get-Control $this "TabControl").SelectedTab
                            $tabList            = $selectedTab.Controls["TabList"]
                            $selectedPackages   = @($tabList.SelectedItems)
                                                        
                            & $NewStatus "Aktualisiere ausgewählte Chocolatey-Pakete..."
                            foreach ($package in $selectedPackages) {

                                & $NewStatus "Aktualisiere $($package.Name)..."
                                Update-Application -Name $package.Name -Manager "Chocolatey"
                                $tabList.SetSelected($tabList.Items.IndexOf($package), $false)
                            }
                            & $NewStatus "Aktualisierung abgeschlossen." -Final
                        }
                    }
                    # Pakete installieren Button
                    InstallButton = @{
                        Control     = "Button"
                        Name        = "InstallButton"
                        Visible     = $false
                        Text        = "Installieren"
                        Dock        = "Bottom"
                        Font        = Get-Font "SidebarButton"
                        Add_Click   = { 
                            $NewStatus       = { param($msg, [switch]$Final) Update-Status -Label (Get-ProcessLabel $this) -Message $msg -Delay 2 -Final:$Final }
                            $selectedTab     = (Get-Control $this "TabControl").SelectedTab
                            $tabList         = $selectedTab.Controls["TabList"]
                            $checkedPackages = @($tabList.CheckedItems)

                            & $NewStatus "Installiere ausgewählte Chocolatey-Pakete..."
                            $tabList.ClearSelected()
                            foreach ($package in $checkedPackages) {

                                & $NewStatus "Installiere $($package.Name)..."
                                Install-Application -Name $package.Id -Manager "Chocolatey"
                                $tabList.SetItemChecked($tabList.Items.IndexOf($package), $false)
                            }
                            & $NewStatus "Installation abgeschlossen." -Final

                        }
                    }
                    # Pakete deinstallieren Button
                    UninstallButton = @{
                        Control     = "Button"
                        Text        = "Deinstallieren"
                        Dock        = "Bottom"
                        Font        = Get-Font "SidebarButton"
                        Visible     = $false
                        Add_Click   = { 
                            $NewStatus          = { param($msg, [switch]$Final) Update-Status -Label (Get-ProcessLabel $this) -Message $msg -Delay 2 -Final:$Final }
                            $selectedTab        = (Get-Control $this "TabControl").SelectedTab
                            $tabList            = $selectedTab.Controls["TabList"]
                            $selectedPackages   = @($tabList.SelectedItems)

                            & $NewStatus "Deinstalliere ausgewählte Chocolatey-Pakete..."
                            foreach ($package in $selectedPackages) {

                                & $NewStatus "Deinstalliere $($package.Name)..."
                                Uninstall-Application -Name $package.Name -Manager "Chocolatey"
                                $tabList.Items.Remove($package)
                            }
                            & $NewStatus "Deinstallation abgeschlossen." -Final
                        }
                    }
                }
            }
        }
        Events      = @{
            Load = {
                Write-Information "Lade Chocolatey-Tab..."
                $selectedTab = (Get-Control $this "TabControl").SelectedTab

                if ($selectedTab.Text -eq "Info") {
                    Write-Information "Aktualisiere Version-Label..."
                    (Get-Control $this "TabLabel").Text = "Chocolatey Version: " + (Get-Chocolatey -Version)
                    

                }
            }
            Shown = {
                Write-Information "Prüfe Chocolatey-Installationsstatus..."
                # Chocolatey-Installationsstatus prüfen
                if (Get-Chocolatey -Test) {
                    (Get-Control $this "UninstallChocoButton").Visible  = $true # Chocolatey deinstallieren Button anzeigen
                    (Get-Control $this "VersionLabel").Text += (Get-Chocolatey -Version) # Chocolatey-Version anzeigen
                } else {
                    (Get-Control $this "InstallChocoButton").Visible    = $true # Chocolatey installieren Button anzeigen 
                    (Get-Control $this "VersionLabel").Text += "Nicht installiert" # Hinweis auf fehlende Installation
                }

                if ((Get-Control $this "TabControl").SelectedTab.Text -eq "Suche") {
                    (Get-Control $this "SearchBox").Focus() # Fokus auf Suchbox setzen, wenn Suche-Tab aktiv ist
                }

            }
        }
    }
    WinGet      = @{
        Properties  = @{
            Text        = "WinGet"
            Icon        = Get-Icon "WinGet"
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
                        # Dock        = "Fill"
                        BackColor   = Get-Color "Dark"
                        ForeColor   = Get-Color "Accent"
                        # Font        = Get-Font -Name "Consolas" -Size 10
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
                            & $AppInfo.DebugText "Tab gewechselt: $($this.SelectedTab.Text)"
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
                        Font        = Get-Font "LabelButton"
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
                        Font        = Get-Font "Button"
                        Add_Click = {                          
                            Get-WinGet -ShowText { param($msg, [switch]$Final) Update-Status -Label (Get-ProcessLabel $this) -Message $msg -Delay 2 -Final:$Final } -Uninstall
                        }
                    }
                    InstallWinGetButton     = @{
                        Control     = "Button"
                        Text        = "WinGet hinzufügen"
                        Dock        = "Top"
                        Enabled     = $false
                        Font        = Get-Font "Button"
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
                        Font        = Get-Font "Button"
                        Add_Click   = { 
                            $ShowText = { param($msg, [switch]$Final) Update-Status -Label (Get-ProcessLabel $this) -Message $msg -Delay 2 -Final:$Final }

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
                        Font    = Get-Font "Button"
                        
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
    DeviceName  = @{
        Properties = @{
            Text = "Neuer Gerätename"
            ClientSize  = [Size]::new(350,50)
            Padding     = [Padding]::new(5)
            FormBorderStyle = "FixedDialog"
            Icon = Get-Icon "Default"
        }
        Controls = @{
            TableLayout = @{
                Control = "TableLayoutPanel"
                Dock    = "Fill"
                Padding = [Padding]::new(0)
                Column  = @( 220, , "30" )
                Row     = @( "AutoSize" )
                Controls = @{
                    TextBox = @{
                        Control = "TextBox"
                        Position = 0,0
                        Font = [Font]::new("Consolas", 17)
                        ForeColor = Get-Color "Accent"
                        BackColor = Get-Color "Dark"
                        TextAlign = "Center"
                        BorderStyle = "None"
                        Text = $env:COMPUTERNAME
                        Multiline = $false
                    }
                    Button = @{
                        Control = "Button"
                        Position = 2,0
                        Text = "Ändern"
                        FlatStyle = "Flat"
                        TextAlign = "MiddleCenter"
                        BackColor = Get-Color "Dark"
                        ForeColor = Get-Color "Accent"
                        Add_Click = { Set-DeviceName -NewName $this.Controls["TextBox"].Text }
                    }
                }
            }
        }
        Events = @{
            Shown = { 
                (Get-Control $this "TextBox").Focus()
             }
        }
    }
}




Start-Form $FormConfig.Main
# Start-Form $FormConfig.About
# Start-Form $FormConfig.Chocolatey
# Start-Form $FormConfig.WinGet
# Start-Form $FormConfig.DeviceName
