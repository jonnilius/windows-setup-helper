using namespace System.Windows.Forms
using namespace System.Drawing
using namespace Console


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
    Version    = "0.9.5"
    Author     = "jonnilius"
    Company    = "BORINAS"
    License    = "MIT License"
}
$global:Color = @{
    Accent     = "#C0393B"
    Dark       = "#2D3436"
    White      = "#EEEEEE"
}


# $ErrorActionPreference = "SilentlyContinue"

$env:PSModulePath += ";$PSScriptRoot\Modules"
Import-Module "$PSScriptRoot\Modules\Utils.psm1"
Import-Module "$PSScriptRoot\Modules\Forms.psm1"
Import-Module "$PSScriptRoot\Modules\Chocolatey.psm1"

$ChocoSetupList = Read-Chocolatey -SetupList



Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization
[System.Windows.Forms.Application]::EnableVisualStyles()

# global-Variablen
$global:restartScript = $false
$global:LabelToolTip = [ToolTip]::new() # Tooltip für Labels


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
                ForeColor = [ColorTranslator]::FromHtml("#C0393B")
            }
            Header = @{
                Control = "Panel"
                Height = 50
                Dock = "Top"
                BackColor = [ColorTranslator]::FromHtml("#C0393B")
            }
            Footer = @{
                Control = "Panel"
                Height = 15
                Dock = "Bottom"
                BackColor = [ColorTranslator]::FromHtml("#C0393B")
            }
        }
        Events = @{
            Shown = { $this.Activate() }
        }
            
    }
    Chocolatey = @{
        Properties = @{
            Text = "$($AppInfo.Name) - Chocolatey"
            ClientSize = [Size]::new(600,300)
            Icon = Get-Icon "Chocolatey"
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
$Main = New-Form $FormConfig.Main.Properties

$ChocoPanel = New-Panel $FormConfig.Panel.Chocolatey
$ChocoListLabel = New-Label $FormConfig.Label.ChocoListLabel
$ChocoListBox   = New-CheckedListBox "ChocoListBox"
$ChocoListInstall = New-Button -Config $FormConfig.Button.ChocoListInstall
$ChocoListMore = New-Button -Config $FormConfig.Button.ChocoListMore

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
    $ChocoListBox.Items.Add($item, $false) | Out-Null
}
if (Read-Chocolatey -Installed) {
    $ChocoPanel.Controls.AddRange(@($ChocoListBox, $ChocoListLabel, $ChocoListInstall, $ChocoListMore))
} else {
    $ChocoPanel.Controls.AddRange(@($NoChocoMessage, $InstallChocoButton))
}

$Header = & {
    # Label
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "WINDOWS SETUP HELPER"
    $label.ForeColor = [ColorTranslator]::FromHtml($Colors.Dark)
    $label.BackColor = [ColorTranslator]::FromHtml($Colors.Accent)
    $label.Font = New-Object System.Drawing.Font("Consolas", 24, [FontStyle]::Bold)
    $label.Dock = "Fill"
    $label.TextAlign = "MiddleCenter"
    $label.Add_DoubleClick({
        # Neustart des Skripts
        $global:restartScript = $true
        $Main.Close()
    })
    # Panel
    $header = New-Panel $FormConfig.Panel.Header
    $header.Controls.Add($label)

    return $header
}
$Footer = & {
    $About = & {
        $label = New-Object System.Windows.Forms.Label
        $label.Text = "About".ToUpper()
        $label.Font = New-Object System.Drawing.Font("Consolas", 8, [FontStyle]::Underline)
        $label.BackColor = [ColorTranslator]::FromHtml($Colors.Accent)
        $label.ForeColor = [ColorTranslator]::FromHtml($Colors.Dark)
        $label.Location = [Point]::New(5,3)
        $label.Cursor = [Cursors]::Hand
        $LabelToolTip.SetTooltip($label, "Informationen über das Skript")
        $label.Add_Click({ AboutForm $FormConfig })

        return $label
    }
    $Version = & {
        $label = New-Object System.Windows.Forms.Label
        $label.Text = "Version $($AppInfo.Version)"
        $label.Font = New-Object System.Drawing.Font("Consolas", 8, [FontStyle]::Italic)
        $label.BackColor = [ColorTranslator]::FromHtml($Colors.Accent)
        $label.ForeColor = [ColorTranslator]::FromHtml($Colors.Dark)
        $label.Location = [Point]::New(150,3)

        return $label
    }
    $Debloat = & {
        $label = New-Object System.Windows.Forms.Label
        $label.Text = "DEBLOAT"
        $label.Font = New-Object System.Drawing.Font("Consolas", 8, [FontStyle]::Underline)
        $label.BackColor = [ColorTranslator]::FromHtml($Colors.Accent)
        $label.ForeColor = [ColorTranslator]::FromHtml($Colors.Dark)
        $label.Location = [Point]::New(330,3)
        $label.Cursor = [Cursors]::Hand
        $LabelToolTip.SetTooltip($label, "Mehr Optionen")
        $label.Add_Click({ DebloatForm $FormConfig })
        
        return $label
    }
    $Panel = New-Panel $FormConfig.Panel.Footer
    $Panel.Controls.AddRange(@($About, $Version, $Debloat))

    return $Panel
}


<# EVENTS #>
$ChocoListInstall.Add_Click({ 
    $selectedPrograms = @()
    foreach ($item in $ChocoListBox.CheckedItems) {
        $selectedPrograms += $item.Id
    }

    
    if ($selectedPrograms.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Bitte wählen Sie mindestens ein Programm aus!", "Fehler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    else {
        choco feature enable -n allowGlobalConfirmation
        $ChocoPanel.Controls.Remove($ChocoListInstall)
        $ChocoPanel.Controls.Remove($ChocoListMore)
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
        $ChocoPanel.Controls.Add($ChocoListInstall)
        $ChocoPanel.Controls.Add($ChocoListMore)

        [System.Windows.Forms.MessageBox]::Show("Alle ausgewählten Programme wurden erfolgreich installiert!", "Erfolg", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        $ChocoListBox.Items.Clear() # Liste leeren
        foreach ($program in $ChocoSetupList.GetEnumerator()) {
            $item = [PSCustomObject]@{
                Id   = $program.Key
                Name = $program.Value
            }
            $ChocoListBox.Items.Add($item, $false) | Out-Null
        }
    }
})
$ChocoListMore.Add_Click({ ChocolateyForm $FormConfig })


$Main.Controls.AddRange(@($ChocoPanel, $Header, $Footer))
$Main.Add_Shown({ $Main.Activate() })
[void]$Main.ShowDialog()


<# Skript-Neustart #>
if ($global:restartScript) { 
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    [System.Environment]::Exit(0)
 }

