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
# Blende die PowerShell-Konsole aus
# & {
#     Add-Type -Name Win -Namespace Console -MemberDefinition '
#   [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
#   [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
# '
#     $consolePtr = [Console.Win]::GetConsoleWindow()
#     [Console.Win]::ShowWindow($consolePtr, 0)  # 0 = SW_HIDE
# }
$global:AppInfo = @{
    Name       = "Windows Setup Helper"
    Version    = "0.9.6"
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

$ChocoSetupList = Read-Chocolatey -SetupList




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
        About = @{
            Padding = [Padding]::new(10)
        }
        DeviceName = @{
            Padding = [Padding]::new(10)
        }
        Debloat = @{
            Padding = [Padding]::new(10,5,10,5)
        }
        Chocolatey = @{
            Padding = [Padding]::new(10)
            ForeColor = [ColorTranslator]::FromHtml("#C0393B")
        }
        Header = @{
            Height = 50
            Dock = "Top"
            BackColor = [ColorTranslator]::FromHtml("#C0393B")
        }
        Footer = @{
            Height = 15
            Dock = "Bottom"
            BackColor = [ColorTranslator]::FromHtml("#C0393B")
        }
        Sidebar = @{
            Dock = "Right"
            BackColor = [ColorTranslator]::FromHtml("#C0393B")
            Padding = [Padding]::new(10,5,0,0)
        }
        Space = @{
            Dock = "Fill"
            BackColor = [ColorTranslator]::FromHtml("#EEEEEE")
            Height = 10
        }
    }
    ## Debug-Formular-Konfigurationen (für Entwicklung und Tests)
    Main = @{
        Properties = @{
            Text        = "$($AppInfo.Name) $($AppInfo.Version)"
            ClientSize  = [Size]::new(400,565)
            Icon        = Get-Icon "Main"
        }
        Controls = @{
            ChocolateyPanel = @{
                Control = "Panel"
                Padding = [Padding]::new(10)
                ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
                Controls = [ordered]@{
                    ListBox = @{
                        Control = "CheckedListBox"
                        Font = [Font]::new("Consolas", 9)
                        ForeColor = [ColorTranslator]::FromHtml("#EEEEEE")
                        BackColor = [ColorTranslator]::FromHtml("#2D3436")
                        BorderStyle = "None"
                        DisplayMember = "Name"
                        CheckOnClick = $true
                        Dock = "Fill"
                    }
                    Label = @{
                        Control = "Label"
                        Text = "Wählen Sie die Programme aus, die Sie installieren möchten:"
                        Font = [Font]::new("Consolas", 9, [FontStyle]::Italic)
                        Dock = "Top"
                        AutoSize = $false
                        TextAlign = "MiddleCenter"
                    }
                    InstallButton = @{
                        Control = "Button"
                        Name = "InstallButton"
                        Text = "Installieren".ToUpper()
                        Font = [Font]::new("Consolas", 8)
                        Dock = "Bottom"
                    }
                    MoreButton = @{
                        Control = "Button"
                        Name = "MoreButton"
                        Text = ("Chocolatey verwalten").ToUpper()
                        Font = [Font]::new("Consolas", 8)
                        Dock = "Bottom"
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
            Shown = { $this.Activate() }
            FormClosed = { [System.Environment]::Exit(0) }
        }
            
    }
    Chocolatey = @{
        Properties = @{
            Text = "$($AppInfo.Name) - Chocolatey"
            Name = "ChocolateyForm"
            ClientSize = [Size]::new(600,300)
            Icon = Get-Icon "Chocolatey"
            Add_Shown = { 
                $packagesPanel = $this.Controls["PackagePanel"]
                $packagesPanel.Controls.Remove($packagesPanel.Controls["LoadingLabel"])
                $packageList = $packagesPanel.Controls["ListBox"]
                $appList = Read-Chocolatey -AppList
                foreach ($program in $appList) { 
                    [void]$packageList.Items.Add($program)
                }
            }
        }
        Controls = @{
            PackagePanel = @{
                Control     = "Panel"
                Name        = "PackagePanel"
                Dock        = "Fill"
                Padding     = [Padding]::new(10)
                ForeColor   = [ColorTranslator]::FromHtml($Colors.Accent)
                BackColor   = [ColorTranslator]::FromHtml($Colors.Dark)
                Controls    = [ordered]@{
                    ListBox = @{
                        Control = "ListBox"
                        Name = "ListBox"
                        Dock = "Fill"
                        Add_Click = {
                            $updateButton = $this.FindForm().Controls["SidebarPanel"].Controls["UpdateButton"]
                            $removeButton = $this.FindForm().Controls["SidebarPanel"].Controls["UninstallButton"]
                            if ($this.SelectedItems.Count -gt 0) {
                                $updateButton.Visible = $true
                                $removeButton.Visible = $true
                            } else {
                                $updateButton.Visible = $false
                                $removeButton.Visible = $false
                            }
                        }
                    }
                    ProcessInfoLabel = @{
                        Control     = "Label"
                        Name        = "ProcessInfoLabel"
                        # ForeColor   = [ColorTranslator]::FromHtml($Colors.Accent)
                        Dock        = "Bottom"
                        Text        = "Installationsprozess..."
                        TextAlign   = "MiddleCenter"
                        Visible     = $false
                    }
                    ChocoHeader = @{
                        Control = "TableLayoutPanel"
                        ColumnCount = 2
                        ColumnStyles = @(
                            [System.Windows.Forms.ColumnStyle]::new("Percent", 100),
                            [System.Windows.Forms.ColumnStyle]::new("AutoSize")
                        )
                        Height = 30
                        Dock = "Top"
                        Controls = [ordered]@{
                            Label = @{
                                Control = "Label"
                                Text = "INSTALLIERT"
                                ForeColor = [ColorTranslator]::FromHtml($Colors.White)
                                BackColor = [ColorTranslator]::FromHtml("Transparent")
                                AutoSize = $true
                                Font = [Font]::new("Consolas", 13, ([FontStyle]::Bold -bor [FontStyle]::Underline))
                            }
                            SelectAllLabel = @{
                                Control = "Label"
                                Name = "SelectAllLabel"
                                Text = "Alle auswählen"
                                ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
                                AutoSize = $true
                                TextAlign = "MiddleCenter"
                                Font = [Font]::new("Consolas", 8)
                                Cursor = [Cursors]::Hand
                                Add_Click = {
                                    $listBox = $this.FindForm().Controls["PackagePanel"].Controls["ListBox"]
                                    $sidebarPanel = $this.FindForm().Controls["SidebarPanel"]
                                    $updateButton = $sidebarPanel.Controls["UpdateButton"]
                                    $removeButton = $sidebarPanel.Controls["UninstallButton"]
                                    if ($listBox.Items.Count -eq $listBox.SelectedItems.Count) {
                                        $updateButton.Visible = $false
                                        $removeButton.Visible = $false
                                        $listBox.SelectedItems.Clear()
                                        $this.Text = "Alle auswählen"
                                    } else {
                                        $updateButton.Visible = $true
                                        $removeButton.Visible = $true
                                        for ($i = 0; $i -lt $listBox.Items.Count; $i++) { $listBox.SetSelected($i, $true) }
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
                Controls = [ordered]@{
                    RemoveChocoButton = @{
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
                    VersionLabel = @{
                        Control = "Label"
                        Text = "Version: $(Read-Chocolatey -Version)"
                        TextAlign = "MiddleCenter"
                        Dock = "Top"
                        Height = 30
                        Font = [Font]::new("Consolas", 10, [FontStyle]::Bold)
                    }
                    UpdateButton = @{
                        Control = "Button"
                        Name    = "UpdateButton"
                        Text    = "Aktualisieren"
                        Visible = $false
                        Dock    = "Bottom"
                        Font = [Font]::new("Consolas", 8, [FontStyle]::Bold)
                        Add_Click = { UpdateChocoApps $this.FindForm() }
                    }
                    Space = @{
                        Control = "Panel"
                        Dock = "Bottom"
                        Height = 5
                        BackColor = [ColorTranslator]::FromHtml("Transparent")
                    }
                    UninstallButton = @{
                        Control = "Button"
                        Name    = "UninstallButton"

                        Visible = $false
                        Text    = "Entfernen"
                        Dock    = "Bottom"
                        Font    = [Font]::new("Consolas", 8, [FontStyle]::Bold)
                        
                        Add_Click = { UninstallChocoApps $this }
                    }
                }
            }
        }
    }
    About = @{
        Properties = @{
            Text = "About $($AppInfo.Name)"
            ClientSize = [Size]::new(350,400)
            Icon = Get-Icon "About"
            FormBorderStyle = "FixedDialog"
            KeyPreview = $true
        }
        Events = @{
            KeyDown = { if ($_.KeyCode -eq "Escape") { $this.Close() } }
        }
    }
    Debloat = @{
        Properties = @{
            Text = "Tweaks & Debloat"
            ClientSize = [Size]::new(245,125)
            Icon = Get-Icon "Debloat"
            FormBorderStyle = "FixedDialog"
        }
    }
    DeviceName = @{
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
            }
        }
        Events = @{
            Shown = { $Button.Focus() }
        }
    }
}


<### Georgia11 ##########################################################################
*                                                                                       *
*                         .g8"""bgd `7MMF'   `7MF'`7MMF'                                *
*                       .dP'     `M   MM       M    MM                                  *
*                       dM'       `   MM       M    MM                                  *
*                       MM            MM       M    MM                                  *
*                       MM.    `7MMF' MM       M    MM                                  *
*                       `Mb.     MM   YM.     ,M    MM                                  *
*                         `"bmmmdPY    `bmmmmd"'  .JMML.                                *
*                                                                                       *
########################################################################################> 
$Main = New-Form $FormConfig.Main

$ChocoPanel = New-Control $FormConfig.Main.Controls.ChocolateyPanel

# Installationsprozess-Info
$InstallProcessText = New-Object System.Windows.Forms.Label
$InstallProcessText.Text = "Installationsprozess..."
$InstallProcessText.Font = New-Object System.Drawing.Font("Consolas", 9, [FontStyle]::Italic)
$InstallProcessText.AutoSize = $false
$InstallProcessText.TextAlign = "MiddleCenter"
$InstallProcessText.Dock = "Bottom"
$InstallProcessText.Height = 30

# NoChoco-Hinweis
$NoChocoMessage = New-Object System.Windows.Forms.Label
$NoChocoMessage.Text = "Chocolatey ist nicht installiert."
$NoChocoMessage.Font = New-Object System.Drawing.Font("Consolas", 10, [FontStyle]::Italic)
$NoChocoMessage.TextAlign = "MiddleCenter"
$NoChocoMessage.Dock = "Fill"
# Install-Chocolatey-Button
$InstallChocoButton = New-Object System.Windows.Forms.Label
$InstallChocoButton.Text = "INSTALLIEREN"
$InstallChocoButton.Font = New-Object System.Drawing.Font("Consolas", 8, [FontStyle]::Bold)
$InstallChocoButton.Cursor = [Cursors]::Hand
$InstallChocoButton.TextAlign = "MiddleCenter"
$InstallChocoButton.AutoSize = $false
$InstallChocoButton.Dock = "Bottom"
$InstallChocoButton.Add_Click({
    $Main.Cursor = [System.Windows.Forms.Cursors]::AppStarting
    $InstallProcessText.Visible = $true
    # $NoChocoMessage.ForeColor = $Colors.Accent
    $NoChocoMessage.ForeColor = [ColorTranslator]::FromHtml($Colors.Accent)
    $NoChocoMessage.Text = "   Installiere Chocolatey..."
    $InstallChocoButton.Visible = $false
    Start-Sleep -Seconds 1
    # Chocolatey installieren
    Install-Chocolatey
    $NoChocoMessage.Text = "Chocolatey erfolgreich installiert!"
    $InstallProcessText.Text = ""
    $Main.Cursor = [System.Windows.Forms.Cursors]::Default
    Start-Sleep -Seconds 2
    # Fenster schließen
    $global:restartScript = $true
    $InstallChocoForm.Close()
    $Main.Close()
})

# ListBox auffüllen
foreach ($program in $ChocoSetupList.GetEnumerator()) {
    $item = [PSCustomObject]@{
        Id   = $program.Key
        Name = $program.Value
    }
    # $ChocoListBox = $ChocoPanel.Controls["ListBox"]
    $ChocoPanel.Controls["ListBox"].Items.Add($item, $false) | Out-Null
}
if (Read-Chocolatey -Installed) {
    # $ChocoPanel.Controls.AddRange(@($ChocoListBox, $ChocoListLabel, $ChocoListInstall, $ChocoListMore))
} else {
    $ChocoPanel.Controls.AddRange(@($NoChocoMessage, $InstallChocoButton))
}

$Header = New-Control $FormConfig.Main.Controls.Header

$Footer = New-Control $FormConfig.Main.Controls.Footer


<# EVENTS #>
$ChocoPanel.Controls["InstallButton"].Add_Click({ 
    
    $listbox        = $ChocoPanel.Controls["ListBox"]
    $installButton  = $ChocoPanel.Controls["InstallButton"]
    $moreButton     = $ChocoPanel.Controls["MoreButton"]

    $selectedPrograms = @()
    foreach ($item in $listbox.CheckedItems) { $selectedPrograms += $item.Id }

    
    if ($selectedPrograms.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Bitte wählen Sie mindestens ein Programm aus!", "Fehler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    else {
        choco feature enable -n allowGlobalConfirmation
        $ChocoPanel.Controls.Remove($installButton)
        $ChocoPanel.Controls.Remove($moreButton)
        $ChocoPanel.Controls.Add($InstallProcessText)
        $InstallProcessText.Text = "Installiere ausgewählte Programme..."
        $Main.Cursor = [System.Windows.Forms.Cursors]::AppStarting
        foreach ($program in $selectedPrograms) {
            $InstallProcessText.Text = "Installiere $($ChocoSetupList[$program])..."
            Start-Sleep -Seconds 1
            # Installationsprozess starten
            choco install $program -y
            if ($LASTEXITCODE -ne 0) {
                [System.Windows.Forms.MessageBox]::Show("Fehler bei der Installation von $($ChocoSetupList[$program])!", "Fehler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }
            # Kurze Pause zwischen den Installationen
            $InstallProcessText.Text = "Installation von $($ChocoSetupList[$program]) abgeschlossen."
            Start-Sleep -Seconds 2
        }
        $InstallProcessText.Text = "Alle ausgewählten Programme erfolgreich installiert!"
        $Main.Cursor = [System.Windows.Forms.Cursors]::Default
        # Fenster schließen
        Start-Sleep -Seconds 2
        $ChocoPanel.Controls.Remove($InstallProcessText)
        $ChocoPanel.Controls.Add($installButton)
        $ChocoPanel.Controls.Add($moreButton)

        [System.Windows.Forms.MessageBox]::Show("Alle ausgewählten Programme wurden erfolgreich installiert!", "Erfolg", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        $listbox.Items.Clear() # Liste leeren
        foreach ($program in $ChocoSetupList.GetEnumerator()) {
            $item = [PSCustomObject]@{
                Id   = $program.Key
                Name = $program.Value
            }
            $listbox.Items.Add($item, $false) | Out-Null
        }
    }
})
$ChocoPanel.Controls["MoreButton"].Add_Click({ ChocolateyForm $FormConfig })


$Main.Controls.AddRange(@($ChocoPanel, $Header, $Footer))

[void]$Main.ShowDialog()


<# Skript-Neustart #>
if ($global:restartScript) { 
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    [System.Environment]::Exit(0)
 }

