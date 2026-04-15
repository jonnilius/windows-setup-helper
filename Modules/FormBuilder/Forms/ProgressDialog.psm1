function Test-ProgressDialog {
    param ( [switch]$Title, [switch]$Status )

    $progress = switch ($true) {
        $Title  { $script:ProgressDialogTitle }
        $Status { $script:ProgressDialogStatus }
        default { $script:ProgressDialog }
    }
    if ($progress -and -not $progress.IsDisposed) { return $progress }
    return $null 
}
function Write-ProgressDialog {
    <#
    .SYNOPSIS
    ProgressDialog - Ein benutzerdefinierter Fortschrittsdialog für PowerShell-Formulare
    
    .DESCRIPTION
    Diese Funktion erstellt die Konfiguration für einen Fortschrittsdialog, der in PowerShell-Formularen verwendet werden kann. 
    Sie ermöglicht die Anzeige eines Haupttitels und optional eines Statusuntertitels, um den Fortschritt von Prozessen anzuzeigen.
    
    .PARAMETER Title
    Der Haupttitel des Fortschrittsdialogs.
    
    .PARAMETER Status
    Der optionale Statusuntertitel des Fortschrittsdialogs.
    
    .EXAMPLE
    Ein Beispiel für die Verwendung der Funktion.
        
        Show-ProgressDialog -Title "Dateien werden kopiert..." -Status "Bitte warten Sie, während die Dateien kopiert werden."
    
    .NOTES
    Allgemeine Hinweise zur Funktion.
    #>
    param( [string]$Title = "Prozess läuft...", [string]$Status = $null )

    # Erstellt die Konfiguration für den Fortschrittsdialog basierend auf den übergebenen Parametern
    $FormConfig = @{
        Properties = @{ 
            Name            = "ProgressDialog"
            Text            = $Title
            Size            = [Size]::new(500, 95)
            FormBorderStyle = "FixedDialog"
            MaximizeBox     = $false
            MinimizeBox     = $false
            ShowInTaskbar   = $false
            Padding         = [Padding]::new(5) 
        }
        Controls = @{
            ProgressTitle = @{ 
                Control     = "Label"
                Dock        = "Fill"
                Height      = 0
                Text        = $Title
                Font        = Get-Font -Name "Consolas" -Size 12 -Style "Bold"
                TextAlign   = "MiddleCenter"
                Padding     = [Padding]::new(0,10,0,0) 
            }
            ProgressStatus = @{ 
                Control     = "Label"
                Dock        = "Fill"
                Text        = $Status
                Font        = Get-Font -Name "Consolas" -Size 10 -Style "Regular"
                TextAlign   = "MiddleCenter" 
                Visible     = $false
            }
        }
        Events = @{
            FormClosed = { Clear-ProgressDialog }
        }
    }

    # Wenn ein Statustext übergeben wurde, füge ein zusätzliches Label für den Status hinzu und passe die Größe des Dialogs an
    if ($Status) {
        $FormConfig.Properties.Size = [Size]::new(500,120)

        $controls = $FormConfig.Controls
        $controls["ProgressTitle"].Dock     = "Top"
        $controls["ProgressTitle"].Height   = 34
        $controls["ProgressStatus"].Visible = $true
    }

    # Gibt die Konfiguration für den Fortschrittsdialog zurück, damit sie von der Show-ProgressDialog-Funktion verwendet werden kann
    return $FormConfig
}
function Sync-ProgressDialog {
    <#
    .SYNOPSIS
    Sync-ProgressDialog - Synchronisiert die globalen Variablen für den Fortschrittsdialog mit den aktuellen Steuerelementen des Dialogs.
    
    .DESCRIPTION
    Diese Funktion synchronisiert die globalen Variablen für den Fortschrittsdialog mit den aktuellen Steuerelementen des Dialogs, damit sie für Aktualisierungen verwendet werden können.
    Sie überprüft, ob der Fortschrittsdialog gültig ist, und aktualisiert die globalen Variablen für den Titel und den Status entsprechend den aktuellen Steuerelementen des Dialogs.
    
    .EXAMPLE
    Ein Beispiel für die Verwendung der Funktion.
        
        Sync-ProgressDialog
    
    .NOTES
    Diese Funktion sollte aufgerufen werden, nachdem der Fortschrittsdialog erstellt oder aktualisiert wurde, um sicherzustellen, dass die globalen Variablen korrekt mit den Steuerelementen des Dialogs synchronisiert sind.
    #>
    Write-Debug "Sync-ProgressDialog"
    
    # Wenn der Fortschrittsdialog nicht mehr gültig ist, setze die zugehörigen Variablen zurück und beende die Synchronisierung
    if (-not (Test-ProgressDialog)) { return Clear-ProgressDialog }

    # Synchronisiere die globalen Variablen für den Fortschrittsdialog mit den aktuellen Steuerelementen des Dialogs, damit sie für Aktualisierungen verwendet werden können
    $script:ProgressDialogTitle     = $script:ProgressDialog.Controls["ProgressTitle"]
    $script:ProgressDialogStatus    = $script:ProgressDialog.Controls["ProgressStatus"] 
}
function Clear-ProgressDialog {
    <#
    .SYNOPSIS
    Löscht den Fortschrittsdialog und setzt die zugehörigen globalen Variablen zurück.
    
    .DESCRIPTION
    Diese Funktion setzt die globalen Variablen für den Fortschrittsdialog zurück und gibt den Speicher frei, der von den Steuerelementen verwendet wird.
    
    .EXAMPLE
    Ein Beispiel für die Verwendung der Funktion.
        
        Clear-ProgressDialog
    
    .NOTES
    Allgemeine Hinweise zur Funktion.
    #>
    $script:ProgressDialog          = $null
    $script:ProgressDialogTitle     = $null
    $script:ProgressDialogStatus    = $null
}

<# ProgressDialog Form #>
function Show-ProgressDialog {
    param( [string]$Title = "Prozess läuft...", [string]$Status = $null )
    Write-Debug "Show-ProgressDialog: `$Title=$Title - `$Status=$Status"

    # Wenn Fortschrittsdialog bereits angezeigt wird, aktualisiere ihn mit den übergebenen Informationen
    if (Test-ProgressDialog) { return Update-ProgressDialog -Title $Title -Status $Status }

    # Erstelle den Fortschrittsdialog basierend auf der Konfiguration
    $script:ProgressDialog = $form = New-Form -Config (Write-ProgressDialog -Title $Title -Status $Status)
    Sync-ProgressDialog


    # Zeige den Fortschrittsdialog an
    $form.Show()

    # Verarbeite die Ereignisschleife, damit der Fortschrittsdialog reagiert und aktualisiert werden kann
    if ("System.Windows.Forms.Application" -as [type]) { [Application]::DoEvents() }
}
function Update-ProgressDialog {
    param( [string]$Title = "Prozess läuft...", [string]$Status = $null )
    Write-Debug "Update-ProgressDialog: `$Title=$Title - `$Status=$Status"

    # Wenn kein Fortschrittsdialog angezeigt wird oder es ungültig ist, zeige einen neuen Fortschrittsdialog mit den übergebenen Informationen an
    if (-not (Test-ProgressDialog)) { return Show-ProgressDialog -Title $Title -Status $Status }
    Sync-ProgressDialog

    if ($Title) {
        if ($script:ProgressDialogStatus.Visible -eq $false) {
            $script:ProgressDialog.Size = [Size]::new(500,120)
            $script:ProgressDialogTitle.Dock = "Top"
            $script:ProgressDialogTitle.Height = 34
            $script:ProgressDialogStatus.Visible = $true 
        }
        if ($status)        {
            $script:ProgressDialogTitle.Text = $Title
            $script:ProgressDialogStatus.Text = $Status
        } else {
            $script:ProgressDialogStatus.Text = $Title
        }
    } elseif ($Status) {
        if ($script:ProgressDialogStatus.Visible -eq $true) {
            $script:ProgressDialogStatus.Visible = $false
            $script:ProgressDialog.Size = [Size]::new(500,95)
            $script:ProgressDialogTitle.Dock = "Fill"
            $script:ProgressDialogTitle.Height = 0
        }
        $script:ProgressDialogTitle.Text = $Status
    }
    $script:ProgressDialogTitle.Refresh()
    $script:ProgressDialogStatus.Refresh()
    $script:ProgressDialog.Refresh()

    if ("System.Windows.Forms.Application" -as [type]) { [Application]::DoEvents() } 
}
function Close-ProgressDialog {
    param ( [string]$Title = "Prozess abgeschlossen.", [string]$Status = $null, [int]$Delay = 2 )
    Write-Debug "Close-ProgressDialog"

    # Wenn kein Fortschrittsdialog angezeigt wird oder es ungültig ist, beende die Funktion
    if (-not (Test-ProgressDialog)) { return }
    Sync-ProgressDialog

    # Schließe den Fortschrittsdialog und setze die zugehörigen Variablen zurück
    Update-ProgressDialog -Title $Title -Status $Status
    Start-Sleep -Seconds $Delay
    $script:ProgressDialog.Close()
    Clear-ProgressDialog
}


