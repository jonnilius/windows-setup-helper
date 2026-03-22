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
    Path        = $PSScriptRoot
    DebugMode   = $true
    DebugText   = {
        param ([string]$message)
        if ($AppInfo.DebugMode) { 
            Write-Host "DEBUG: " -ForegroundColor Yellow -NoNewline
            Write-Host $message 
        }
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
    Accent = [ColorTranslator]::FromHtml("#C0393B")
    Dark   = [ColorTranslator]::FromHtml("#2D3436")
    White  = [ColorTranslator]::FromHtml("#EEEEEE")
    Debug1 = [ColorTranslator]::FromHtml("#27AE60")
    Debug2 = [ColorTranslator]::FromHtml("#2980B9")
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
& $AppInfo.DebugText "Lade Module..."
$env:PSModulePath += ";$PSScriptRoot\Modules"
Import-Module "$PSScriptRoot\Modules\Utils.psm1"
Import-Module "$PSScriptRoot\Modules\FormBuilder.psm1"
Import-Module "$PSScriptRoot\Modules\Chocolatey.psm1"


# $script:ChocoSetupList = Read-Chocolatey -SetupList
# & $AppInfo.DebugText "Initialisiere Anwendungsinformationen..."
# $global:AppList = @{
#     Chocolatey  = @{
#         IsInstalled = Get-Command -Name "choco.exe" -ErrorAction SilentlyContinue
#         Install     = { Get-PackageProvider -Name "Chocolatey" -Force | Out-Null; Install-Package -Name "Chocolatey" -ProviderName "Chocolatey" -Force }
#         Uninstall   = { Get-PackageProvider -Name "Chocolatey" -Force | Out-Null; Uninstall-Package -Name "Chocolatey" -ProviderName "Chocolatey" -Force }
#         Version     = { (choco --version).Trim() }
#         AppList     = { choco list --local-only --no-color | Select-Object -Skip 1 }
#     }
#     Edge        = @{
#         IsInstalled = Get-Package -Name "Microsoft Edge" -ErrorAction SilentlyContinue
#         Install     = { Get-PackageProvider -Name "Edge" -Force | Out-Null; Install-Package -Name "Microsoft Edge" -ProviderName "Edge" -Force }
#         Uninstall   = { Get-PackageProvider -Name "Edge" -Force | Out-Null; Uninstall-Package -Name "Microsoft Edge" -ProviderName "Edge" -Force }
#     }
#     OneDrive    = @{
#         IsInstalled = Get-Package -Name "Microsoft OneDrive" -ErrorAction SilentlyContinue
#         Install     = { Get-PackageProvider -Name "OneDrive" -Force | Out-Null; Install-Package -Name "OneDrive" -ProviderName "OneDrive" -Force }
#         Uninstall   = { Get-PackageProvider -Name "OneDrive" -Force | Out-Null; Uninstall-Package -Name "OneDrive" -ProviderName "OneDrive" -Force }
#     }
#     WinGet      = @{
#         IsInstalled     = Get-Command -Name "winget.exe" -ErrorAction SilentlyContinue
#         Version         = ((winget --version).Trim() -replace '^v', '')
#         InstalledList   = Get-WinGetApps -InstalledList
#         SetupList       = Get-WinGetApps -SetupList 
#     }
# }


& $AppInfo.DebugText "Erstelle Hauptformular..."
<# FORM-DATA ############################################################################>
$FormConfig = @{
    Main        = @{
        Properties  = @{
            Text        = $AppInfo.Name
            ClientSize  = [Size]::new(400,370) # Breite, Höhe
            Icon        = Get-Icon "Main"
            Padding     = [Padding]::new(10,0,10,0)
            ForeColor   = $AppDesign.Dark
            BackColor   = $AppDesign.Accent
        }
        Controls    = [ordered]@{
            TabPanel = @{
                Control = "Panel"
                Dock = "Fill"
                Padding = [Padding]::new(0)
                BackColor = $AppDesign.Dark
                ForeColor = $AppDesign.Accent
                Controls = @{
                    ProcessLabel = @{
                        Control     = "Label"
                        Height      = 50
                        Font        = Get-Font "Label" -Name "Consolas"
                        Dock        = "Bottom"
                        TextAlign   = "MiddleCenter"
                        Visible     = $false
                        Add_VisibleChanged = {
                            $this.FindForm().ClientSize = if ($this.Visible) { [Size]::new(360,450) } else { [Size]::new(360,400) }
                        }
                    }
                    TabControl = @{
                        Control     = "TabControl"
                        Dock        = "Fill"
                        Font        = [Font]::new("Consolas", 10)
                        Controls    = [ordered]@{
                            MainTab     = @{
                                Control     = "TabPage"
                                Text        = "Allgemein"
                                Controls    = @{
                                    MainTable = @{
                                        Control     = "TableLayoutPanel"
                                        Dock        = "Fill"
                                        Padding     = [Padding]::new(0)
                                        Column      = @( "40", "40", "20" )
                                        Row         = @( 30, 30, 30, 30, 30, 30, 30, 30, "AutoSize" )
                                        Controls    = @{
                                            SystemLabel = @{
                                                ColumnSpan  = 3
                                                Position    = 0,0
                                                Control     = "Label"
                                                Text        = "System Einstellungen"
                                                Font        = Get-Font "Subtitle"
                                                Dock        = "Fill"
                                                TextAlign   = "BottomCenter"
                                            }

                                            DeviceNameLabel = @{
                                                Position    = 0,1
                                                Control     = "Label"
                                                Text        = "Gerätename:"
                                                Font        = Get-Font "Label" -Style "Bold"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleRight"
                                            }
                                            DeviceNameValue = @{
                                                Position    = 1,1
                                                Control     = "Label"
                                                Text        = $($env:COMPUTERNAME)
                                                Font        = Get-Font "Label"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleCenter"
                                            }
                                            DeviceNameButton = @{
                                                Position    = 2,1
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font "Button"
                                                Dock        = "Fill"
                                                Margin      = [Padding]::new(5,2,5,3)
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
                                    ProcessLabel = @{
                                        Control     = "Label"
                                        Height      = 50
                                        Font        = Get-Font "Label"
                                        Dock        = "Bottom"
                                        TextAlign   = "MiddleCenter"
                                        Visible     = $false
                                        Add_VisibleChanged = {
                                            $this.FindForm().ClientSize = if ($this.Visible) { [Size]::new(360,450) } else { [Size]::new(360,400) }
                                        }

                                    }
                                    TableLayout = @{
                                        Control     = "TableLayoutPanel"
                                        Dock        = "Fill"
                                        Padding     = [Padding]::new(0)
                                        Column      = @( "50", "50" )
                                        Row         = @( 50, 50, 50, "AutoSize" )
                                        Controls    = @{
                                            UninstallOneDrive = @{
                                                Control     = "Button"
                                                Text        = "OneDrive entfernen"
                                                Font        = Get-Font "Button"
                                                Position    = 1,0
                                                Dock        = "Fill"
                                                Margin      = [Padding]::new(5)
                                                Add_Click   = { 
                                                    $processLabel = $this.FindForm().Controls.Find("ProcessLabel", $true)[0]
                                                    Remove-Item "OneDrive" { 
                                                        param([string]$msg, [switch]$final) 
                                                        Update-Status -Label $processLabel -Message $msg -Delay 1 -Final:$final 
                                                    } 
                                                }
                                            }
                                            UninstallEdge = @{
                                                Control     = "Button"
                                                Text        = "Microsoft Edge entfernen"
                                                Font        = Get-Font "Button"
                                                Position    = 1,1
                                                Dock        = "Fill"
                                                Margin      = [Padding]::new(5)
                                                Add_Click   = { 
                                                    $processLabel = $this.FindForm().Controls.Find("ProcessLabel", $true)[0]
                                                    Remove-Item "Edge" { 
                                                        param([string]$msg, [switch]$final) 
                                                        Update-Status -Label $processLabel -Message $msg -Delay 1 -Final:$final 
                                                    } 
                                                }
                                            }   
                                            HideStartMenuIcons = @{
                                                Control     = "Button"
                                                Text        = "Startmenü aufräumen"
                                                Font        = Get-Font "Button"
                                                Position    = 1,2
                                                Dock        = "Fill"
                                                Margin      = [Padding]::new(5)
                                                Add_Click   = { 
                                                    $processLabel = $this.FindForm().Controls.Find("ProcessLabel", $true)[0]
                                                    Remove-Item "StartMenuIcons" { 
                                                        param([string]$msg, [switch]$final) 
                                                        Update-Status -Label $processLabel -Message $msg -Delay 1 -Final:$final 
                                                    }
                                                }
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
                                        Row         = @( "AutoSize", 50, 20 )
                                        Controls    = @{
                                            PaketManagerLabel = @{
                                                ColumnSpan  = 2
                                                Position    = 0,1
                                                Control     = "Label"
                                                Text        = "Paket-Manager"
                                                Font        = Get-Font "Subtitle"
                                                ForeColor   = [ColorTranslator]::FromHtml($Colors.Accent)
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
                                    ProgramList = @{
                                        Control     = "ListBox"
                                        Name        = "ProgramList"
                                        Dock        = "Fill"
                                    }
                                }
                            }
                            PowerTab = @{
                                Control     = "TabPage"
                                Text        = "Energieoptionen"
                                Controls    = @{
                                    PowerTable = @{
                                        Control     = "TableLayoutPanel"
                                        Dock        = "Fill"
                                        Padding     = [Padding]::new(0)
                                        Column      = @( "70", 80, 70 )
                                        Row         = @( 35, 30, 30, 30, 35, 30, 30, 30, "AutoSize" )
                                        Controls    = [ordered]@{
                                            # Row 1 – Im Netzbetrieb
                                            PowerLabelDC = @{
                                                ColumnSpan  = 3
                                                # Position    = 0,0
                                                Control     = "Label"
                                                Text        = "Im Netzbetrieb"
                                                Font        = Get-Font "Subtitle"
                                                Dock        = "Fill"
                                                TextAlign   = "BottomCenter"
                                            }
                                            # Row 2 – Im Netzbetrieb (Energiesparmodus)
                                            StandbyLabelAC = @{
                                                # Position    = 0,1
                                                Control     = "Label"
                                                Text        = "Energiesparmodus:"
                                                Font        = Get-Font "Label" -Style "Bold"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleRight"
                                            }
                                            StandbyValueAC = @{
                                                # Position    = 1,1
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "AC" "Standby" -TextOutput
                                                Font        = Get-Font "Label"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleCenter"
                                            }
                                            StandbyButtonAC = @{
                                                # Position    = 2,1
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font "Button"
                                                Dock        = "Fill"
                                                Margin      = [Padding]::new(5,2,5,3)
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
                                                Font        = Get-Font "Label" -Style "Bold"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleRight"
                                            }
                                            HibernateValueAC = @{
                                                # Position    = 1,2
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "AC" "Hibernate" -TextOutput
                                                Font        = Get-Font "Label"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleCenter"
                                            }
                                            HibernateButtonAC = @{
                                                # Position    = 2,2
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font "Button"
                                                Dock        = "Fill"
                                                Margin      = [Padding]::new(5,2,5,3)
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
                                                Font        = Get-Font "Label" -Style "Bold"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleRight"
                                            }
                                            MonitorValueAC = @{
                                                # Position    = 1,3
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "AC" "Monitor" -TextOutput
                                                Font        = Get-Font "Label"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleCenter"
                                            }
                                            MonitorButtonAC = @{
                                                # Position    = 2,3
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font "Button"
                                                Dock        = "Fill"
                                                Margin      = [Padding]::new(5,2,5,3)
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
                                                Font        = Get-Font "Subtitle"
                                                Dock        = "Fill"
                                                TextAlign   = "BottomCenter"
                                            }
                                            # Row 6 – Im Akkubetrieb (Energiesparmodus)
                                            StandbyLabelDC = @{
                                                # Position    = 0,5
                                                Control     = "Label"
                                                Text        = "Energiesparmodus:"
                                                Font        = Get-Font "Label" -Style "Bold"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleRight"
                                            }
                                            StandbyValueDC = @{
                                                # Position    = 1,5
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "DC" "Standby" -TextOutput
                                                Font        = Get-Font "Label"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleCenter"
                                            }
                                            StandbyButtonDC = @{
                                                # Position    = 2,5
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font "Button"
                                                Dock        = "Fill"
                                                Margin      = [Padding]::new(5,2,5,3)
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
                                                Font        = Get-Font "Label" -Style "Bold"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleRight"
                                            }
                                            HibernateValueDC = @{
                                                # Position    = 1,6
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "DC" "Hibernate" -TextOutput
                                                Font        = Get-Font "Label"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleCenter"
                                            }
                                            HibernateButtonDC = @{
                                                # Position    = 2,6
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font "Button"
                                                Dock        = "Fill"
                                                Margin      = [Padding]::new(5,2,5,3)
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
                                                Font        = Get-Font "Label" -Style "Bold"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleRight"
                                            }
                                            MonitorValueDC = @{
                                                # Position    = 1,7
                                                Control     = "Label"
                                                Text        = Get-PowerStatus "DC" "Monitor" -TextOutput
                                                Font        = Get-Font "Label"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleCenter"
                                            }
                                            MonitorButtonDC = @{
                                                # Position    = 2,7
                                                Control     = "Button"
                                                Text        = "Ändern"
                                                Font        = Get-Font "Button"
                                                Dock        = "Fill"
                                                Margin      = [Padding]::new(5,2,5,3)
                                                Add_Click   = { 
                                                    Update-PowerStatus -PowerScheme "DC" -StatusType "Monitor"
                                                    $this.FindForm().Controls.Find("MonitorValueDC", $true)[0].Text = Get-PowerStatus "DC" "Monitor" -TextOutput
                                                }
                                            }
                                            DisableSleep = @{
                                                ColumnSpan  = 3
                                                # Position    = 0,8
                                                Control     = "Label"
                                                Text        = "Energiesparmodus deaktivieren"
                                                Font        = Get-Font "Label" -Style "Italic"
                                                Dock        = "Fill"
                                                TextAlign   = "MiddleCenter"
                                                Cursor      = "Hand"
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
                                                Add_MouseEnter = { $this.Font = Get-Font "Label" -Style "Italic, Underline" }
                                                Add_MouseLeave = { $this.Font = Get-Font "Label" -Style "Italic" }
                                            }
                                        }
                                    }
                                }
                                Add_Enter = {
                                    $PowerValues = @{
                                        "StandbyValueAC" = Get-PowerStatus "AC" "Standby" -TextOutput
                                        "HibernateValueAC" = Get-PowerStatus "AC" "Hibernate" -TextOutput
                                        "MonitorValueAC" = Get-PowerStatus "AC" "Monitor" -TextOutput
                                        "StandbyValueDC" = Get-PowerStatus "DC" "Standby" -TextOutput
                                        "HibernateValueDC" = Get-PowerStatus "DC" "Hibernate" -TextOutput
                                        "MonitorValueDC" = Get-PowerStatus "DC" "Monitor" -TextOutput
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
                                Add_Leave = {
                                    $this.FindForm().MinimumSize = [Size]::new(0,0)
                                }
                            }
                        }
                        Add_SelectedIndexChanged = {
                            $form           = $this.FindForm()
                            $selectedTab    = $this.SelectedTab

                            $headerLabel    = $form.Controls["Header"]

                            switch ($selectedTab.Text) {
                                "System"            { $headerLabel.Text = $AppInfo.Name.ToUpper() }
                                "Debloat"           { $headerLabel.Text = "WINDOWS DEBLOATER" }
                                "Programme"         { $headerLabel.Text = "PROGRAMMVERWALTUNG" }
                                "Energieoptionen"   { 
                                    $headerLabel.Text = "ENERGIEOPTIONEN" 
                                    $form.MinimumSize = [Size]::new(350,440)
                                }
                            }
                        }
                    }
                }
            }
            MainPanel = @{
                Control     = "TableLayoutPanel"
                Dock       = "Fill"
                BackColor   = $AppDesign.Dark
                Visible     = $false
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
        Events      = @{
            FormClosed  = { 
                [System.Environment]::Exit(0) 
            }
            Load        = { 
                $this.Text += if ($AppInfo.IsAdmin) { " – Administrator".ToUpper() }
            }
            Resize      = { 
                $header = $this.Controls["Header"]
                $header.Font = [Font]::new("Consolas", $(Resize-Form $this 22), [FontStyle]::Bold)
            }
            Shown       = { 
                $this.Activate()
                $header     = $this.Controls["Header"]
                $header.Font = [Font]::new("Consolas", $(Resize-Form $this 22), [FontStyle]::Bold)

                $tabControl = $this.Controls["TabPanel"].Controls["TabControl"]
                $tabControl.SelectedIndex = 0
            }
        }
    }
    About       = @{
        Properties  = @{
            Text = "About - $($AppInfo.Name)"
            ClientSize = [Size]::new(350,400)
            Icon = Get-Icon "About"
            FormBorderStyle = "FixedDialog"
            KeyPreview = $true
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
        Events      = @{
            KeyDown = { if ($_.KeyCode -eq "Escape") { $this.Close() } }
        }
    }
    Chocolatey  = @{
        Properties  = @{
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
                                            $sidebarPanel = $this.FindForm().Controls["SidebarPanel"]
                                            $sidebarPanel.Controls["UpdateButton"].Visible   = $this.SelectedItems.Count -gt 0
                                            $sidebarPanel.Controls["UninstallButton"].Visible   = $this.SelectedItems.Count -gt 0
                                            
                                            $packagePanel = $this.FindForm().Controls["PackagePanel"]
                                            $packagePanel.Controls["SelectLabel"].Text      = if ($this.Items.Count -eq $this.SelectedItems.Count) { "Alle abwählen" } else { "Alle auswählen" }
                                        }
                                    }
                                    Process = @{
                                        Control = "Label"
                                        Dock = "Bottom"
                                        TextAlign = "MiddleCenter"
                                        Visible = $false
                                        Height = 30
                                        ForeColor = $AppDesign.Accent
                                    }
                                }
                                Add_Enter = {
                                    $this.FindForm().Controls["SidebarPanel"].Controls["InstallButton"].Visible = $false
                                }
                            }
                            AddTab = @{
                                Control     = "TabPage"
                                Text        = "Hinzufügen"
                                Controls    = @{
                                    AddList = @{
                                        Control         = "CheckedListBox"
                                        Name            = "AddList"
                                        Items           = Read-Chocolatey -SetupList
                                        Add_ItemCheck   = {
                                            param($src, $e)
                                            $count = $src.CheckedItems.Count
                                            if ($e.NewValue -eq [CheckState]::Checked) { $count++ } else { $count-- }

                                            $form = $this.FindForm()
                                            $form.Controls["SidebarPanel"].Controls["InstallButton"].Visible = $count -gt 0
                                        }
                                    }
                                    Process = @{
                                        Control = "Label"
                                        Dock = "Bottom"
                                        TextAlign = "MiddleCenter"
                                        Visible = $false
                                        Height = 30
                                        ForeColor = $AppDesign.Accent
                                    }
                                }
                            }
                        }
                        Add_SelectedIndexChanged = {
                            $selectedTab    = $this.SelectedTab
                            $installedList  = $this.Controls["ManageTab"].Controls["InstalledList"]
                            $addList        = $this.Controls["AddTab"].Controls["AddList"]
                            # Sidebar-Buttons
                            $sidebarPanel   = $this.FindForm().Controls["SidebarPanel"]
                            $installButton  = $sidebarPanel.Controls["InstallButton"]
                            $updateButton   = $sidebarPanel.Controls["UpdateButton"]
                            $removeButton   = $sidebarPanel.Controls["UninstallButton"]

                            switch ($selectedTab.Name) {
                                "ManageTab" {
                                    if ($installedList.Items.Count -eq 0){
                                        & $AppInfo.DebugText "Lade installierte Programme..."
                                        foreach ($program in Read-Chocolatey -AppList) { 
                                            [void]$installedList.Items.Add($program) 
                                        }
                                    }
                                }
                                # "AddTab" {
                                #     # $addList = $this.Controls["AddTab"].Controls["AddList"]
                                #     if ($addList.Items.Count -eq 0) {
                                #         & $AppInfo.DebugText "Lade verfügbare Programme..."
                                #         foreach ($program in Read-Chocolatey -SetupList){
                                #             $item = [PSCustomObject]@{
                                #                 Id      = $program.Key
                                #                 Name    = $program.Value
                                #             }
                                #             $addList.Items.Add($item, $false) | Out-Null

                                #         }
                                #     }
                                # }
                                {$_ -ne "ManageTab"} {
                                    $installedList.ClearSelected()
                                    $updateButton.Visible   = $false
                                    $removeButton.Visible   = $false
                                }
                                {$_ -ne "AddTab"} {
                                    $addList.ClearSelected()
                                    foreach ($index in $addList.CheckedIndices) { $addList.SetItemChecked($index, $false) }
                                    $installButton.Visible  = $false
                                }
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
                        Text    = "Chocolatey entfernen"
                        Dock    = "Top"
                        Enabled = $false
                        Font    = Get-Font "Button"
                        Add_Click = { 
                            $tabControl = $this.FindForm().Controls["PackagePanel"].Controls["TabControl"]
                            if ($tabControl.SelectedTab.Name -eq "ManageTab") { 
                                $tabControl.Controls["ManageTab"].Controls["Process"].Visible = $true 
                                $currentTab = $tabControl.Controls["ManageTab"]
                            } elseif ($tabControl.SelectedTab.Name -eq "AddTab") { 
                                $tabControl.Controls["AddTab"].Controls["Process"].Visible = $true 
                                $currentTab = $tabControl.Controls["AddTab"]
                            }

                            if (-not (Show-MessageBox "ConfirmUninstallChocolatey")) { return }
                            
                            $this.FindForm().Cursor = [Cursors]::AppStarting
                            
                            Uninstall-Chocolatey { param($msg, [switch]$Final) Update-Status -Label $currentTab.Controls["Process"] -Message $msg -Delay 2 -Final:$Final }
                            $this.FindForm().Cursor = [Cursors]::Default
                            
                            Show-MessageBox "UninstallChocolateySuccess"
                        }
                    }
                    InstallChocoButton = @{
                        Control = "Button"
                        Text    = "Chocolatey hinzufügen"
                        Dock    = "Top"
                        Enabled = $false
                        Font    = Get-Font "Button"
                        Add_Click = { 
                            $tabControl = $this.FindForm().Controls["PackagePanel"].Controls["TabControl"]
                            if ($tabControl.SelectedTab.Name -eq "ManageTab") { 
                                $tabControl.Controls["ManageTab"].Controls["Process"].Visible = $true 
                                $currentTab = $tabControl.Controls["ManageTab"]
                            } elseif ($tabControl.SelectedTab.Name -eq "AddTab") { 
                                $tabControl.Controls["AddTab"].Controls["Process"].Visible = $true 
                                $currentTab = $tabControl.Controls["AddTab"]
                            }

                            $this.FindForm().Cursor = [Cursors]::AppStarting
                            
                            Install-Chocolatey { param($msg, [switch]$Final) Update-Status -Label $currentTab.Controls["Process"] -Message $msg -Delay 2 -Final:$Final }
                            $this.FindForm().Cursor = [Cursors]::Default
                            
                            Show-MessageBox "InstallChocolateySuccess"
                        }
                    }
                    VersionLabel = @{
                        Control = "Label"
                        Text = "Version: $(Read-Chocolatey -Version)"
                        TextAlign = "MiddleCenter"
                        Dock = "Top"
                        Height = 20
                        Font = [Font]::new("Consolas", 10, [FontStyle]::Bold)
                    }
                    NameLabel = @{
                        Control = "Label"
                        Text = "Chocolatey"
                        TextAlign = "MiddleCenter"
                        Dock = "Top"
                        Font = [Font]::new("Cascadia Code", 14, [FontStyle]::Bold)
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
                & $AppInfo.DebugText "Event: Chocolatey Form Shown"
                $tabControl = $this.Controls["PackagePanel"].Controls["TabControl"]

                # Installierte Programme laden
                $InstalledList = $tabControl.Controls["ManageTab"].Controls["InstalledList"]
                & $AppInfo.DebugText "Lade installierte Programme..."
                foreach ($program in Read-Chocolatey -AppList) { 
                    [void]$InstalledList.Items.Add($program) 
                }


                # Chocolatey-Installationsstatus
                $sidebarPanel   = $this.Controls["SidebarPanel"]
                if (Get-Chocolatey) { 
                    $sidebarPanel.Controls["UninstallChocoButton"].Enabled = $true 
                } else { 
                    $sidebarPanel.Controls["InstallChocoButton"].Enabled = $true 
                }

            }
        }
    }
    Debloat     = @{
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
    WinGet  = @{
        Properties  = @{
            Text        = "$($AppInfo.Name) - WinGet"
            ClientSize  = [Size]::new(600,300)
            Icon        = Get-Icon "WinGet"
        }
        Controls    = @{
            PackagePanel = @{
                Control     = "Panel"
                Dock        = "Fill"
                Padding     = [Padding]::new(10,10,10,5)
                Controls    = [ordered]@{
                    TabControl = @{
                        Control     = "TabControl"
                        Dock        = "Fill"
                        BackColor   = $AppDesign.Dark
                        ForeColor   = $AppDesign.Accent
                        Font        = Get-Font -Name "Consolas" -Size 10
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

                                            $sidebarPanel.Controls["UpdateAppButton"].Visible      = $this.SelectedItems.Count -gt 0
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
                        ForeColor   = $AppDesign.Accent
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
                        ForeColor   = $AppDesign.Accent
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
                ForeColor   = $AppDesign.Dark
                BackColor   = $AppDesign.Accent
                Padding     = [Padding]::new(10,5,0,0)
                Controls    = [ordered]@{
                    UninstallWinGetButton   = @{
                        Control     = "Button"
                        Text        = "WinGet entfernen"
                        Dock        = "Top"
                        Enabled     = $false
                        Font        = Get-Font "Button"
                        Add_Click = {                          
                            $processLabel   = $this.FindForm().Controls["PackagePanel"].Controls["ProcessLabel"]
                            Get-WinGet -ShowText { param($msg, [switch]$Final) Update-Status -Label $processLabel -Message $msg -Delay 2 -Final:$Final } -Uninstall
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
                            $processLabel = $this.FindForm().Controls["PackagePanel"].Controls["ProcessLabel"]
                            $ShowText = { param($msg, [switch]$Final) Update-Status -Label $processLabel -Message $msg -Delay 2 -Final:$Final }

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
                            $WinGetList = Get-WinGet -List
                            # $checkedList = foreach ($index in $installedList.SelectedItems) { Get-WinGet -List | Where-Object { $_.Name -eq $index } }
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
            Shown = { 
                $tabControl     = $this.Controls["PackagePanel"].Controls["TabControl"]
                $InstalledList  = $tabControl.Controls["ManageTab"].Controls["InstalledList"]
                $sidebarPanel   = $this.Controls["SidebarPanel"]
                
                # Installierte Programme laden
                foreach ($program in Get-WinGet -List) { 
                    [void]$InstalledList.Items.Add($program) 
                }
                
                # SidebarPanel
                $sidebarPanel.Controls["WinGetVersionLabel"].Text += if (Get-WinGet -Version) { Get-WinGet -Version } else { "Nicht installiert" }
                if (Get-WinGet) { 
                    $sidebarPanel.Controls["UninstallWinGetButton"].Enabled = $true 
                } else { 
                    $sidebarPanel.Controls["InstallWinGetButton"].Enabled   = $true 
                }

            }
        }
    }
}

& $AppInfo.DebugText "Starte Hauptformular..."
Start-Form $FormConfig.Main
# Start-Form $FormConfig.Chocolatey
Start-Form $FormConfig.WinGet