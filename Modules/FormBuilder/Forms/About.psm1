$FormConfig = @{
    Properties  = @{
        Text            = "About"
        Icon            = "About"
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
Windows Setup Helper ist ein reines PowerShell-Skript zum Einrichten und Konfigurieren von Windows-Systemen.`n
Mit einer übersichtlichen grafischen Oberfläche ermöglicht es die schnelle Installation und Verwaltung von Programmen über Chocolatey und WinGet, das Ändern von Systemeinstellungen wie Gerätename oder Zeitserver sowie das Anzeigen wichtiger Systeminformationen.`n
Das Skript richtet sich an alle, die Windows-PCs effizient und wiederholbar einrichten möchten - egal ob für den privaten Gebrauch, im Unternehmen oder in Bildungseinrichtungen.`n
Durch die Integration von Automatisierung und Benutzerfreundlichkeit spart der Windows Setup Helper Zeit und reduziert Fehlerquellen bei der Systemeinrichtung.`n
Version: $($AppInfo.Version)
Entwickler: $($AppInfo.Author)
Lizenz: MIT

Credits:
 - Uninstall Microsoft Edge: bibicadotnet
 - Uninstall Chocolatey: chocolatey.org
 - UltraUXThemePatcher: mhoefs.eu
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
function Start-AboutUI {
    Start-Form $FormConfig
}