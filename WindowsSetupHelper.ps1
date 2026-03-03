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
    Version    = "0.9.2"
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

$ChocoSetupList = Read-Chocolatey -SetupList



Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization
[System.Windows.Forms.Application]::EnableVisualStyles()

# global-Variablen
$global:restartScript = $false
$global:LabelToolTip = [ToolTip]::new() # Tooltip für Labels


<# FUNKTIONEN ############################################################################>


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
$Main = New-Form "Main"
$ChocoPanel = New-Panel "Chocolatey"
$ChocoListBox = New-CheckedListBox "ChocoListBox"


# Title
$ChocoLabel = &{
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Chocolatey-Pakete"
    $label.Font = New-Object System.Drawing.Font("Consolas", 15, [FontStyle]::Bold)
    $label.AutoSize = $false
    $label.Dock = "Top"
    $label.Height = 30
    $label.TextAlign = "MiddleCenter"

    return $label
}
# Install-Button
$ChocoInstallButton = New-Object System.Windows.Forms.Button
$ChocoInstallButton.Text = "Installieren"
$ChocoInstallButton.FlatStyle = "Flat"
$ChocoInstallButton.Font = New-Object System.Drawing.Font("Consolas", 9, [FontStyle]::Bold)
$ChocoInstallButton.Dock = "Bottom"
$ChocoInstallButton.Add_Click({ 
    $selectedPrograms = @()
    foreach ($item in $ChocoListBox.CheckedItems) {
        $selectedPrograms += $item.Id
    }

    
    if ($selectedPrograms.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Bitte wählen Sie mindestens ein Programm aus!", "Fehler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    else {
        choco feature enable -n allowGlobalConfirmation
        $ChocoPanel.Controls.Remove($ChocoInstallButton)
        $ChocoPanel.Controls.Remove($MoreChocoLink)
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
        $ChocoPanel.Controls.Add($ChocoInstallButton)
        $ChocoPanel.Controls.Add($MoreChocoLink)

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
# Mehr-Optionen-Link
$MoreChocoLink = New-Object System.Windows.Forms.Label
$MoreChocoLink.Text = "Aktualisieren / Deinstallieren"
$MoreChocoLink.Font = New-Object System.Drawing.Font("Consolas", 8)
$MoreChocoLink.TextAlign = "BottomCenter"
$MoreChocoLink.Height = 20
$MoreChocoLink.AutoSize = $false
$MoreChocoLink.Dock = "Bottom"
$MoreChocoLink.Cursor = [Cursors]::Hand
$MoreChocoLink.Add_Click({ ChocolateyForm })
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
    $ChocoPanel.Controls.AddRange(@($ChocoListBox, $ChocoLabel, $ChocoInstallButton, $MoreChocoLink))
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
    $header = New-Panel "Header"
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
        $label.Add_Click({ AboutForm })

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
        $label.Add_Click({ DebloatForm })
        
        return $label
    }
    $Panel = New-Panel "Footer"
    $Panel.Controls.AddRange(@($About, $Version, $Debloat))

    return $Panel
}
$Main.Controls.AddRange(@($ChocoPanel, $Header, $Footer))
$Main.Add_Shown({ $Main.Activate() })
[void]$Main.ShowDialog()


<# Skript-Neustart #>
if ($global:restartScript) { 
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    [System.Environment]::Exit(0)
 }

