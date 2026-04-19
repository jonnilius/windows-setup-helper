using namespace System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms

# Globale Variablen für den Modulbetrieb definieren, um Statusaktualisierungen und Caching zu ermöglichen
$script:UpdateLabel = { param($msg, [switch]$Final) Update-ProcessLabel $this $msg 2 -Final:$Final }
$script:Cache       = @{
    IsInstalled   = $null
    Version       = $null
    InstalledPackages = $null
    SuggestedPackages = $null

    SearchResults  = @{}
    PackageDetails = @{}
}


$FormConfig  = @{
    Properties  = @{
        Text        = "Chocolatey"
        ClientSize  = [Size]::new(650,440)
        Icon        = "Chocolatey"
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
                                    # Dock            = "Fill"
                                    SelectionMode   = "MultiExtended"
                                    Visible         = $false

                                    Add_SelectedIndexChanged = {
                                        param($listbox, $e)
                                        $selectedItems    = $listbox.SelectedItems

                                        # Schutz gegen unbeabsichtigte Auslösung während der Aktualisierung der Liste
                                        if ($listbox.Tag -is [hashtable] -and $listbox.Tag.SuppressSelectionChanged) { return }

                                        # Installieren-Button nur anzeigen, wenn mindestens ein Paket ausgewählt ist
                                        (Get-Control $this "InstallButton").Visible = $selectedItems.Count -gt 0
                                        
                                        # Paketauswahl auswerten und Details entsprechend anzeigen; bei Mehrfachauswahl wird bewusst auf die Anzeige von Details verzichtet, um Verwirrung zu vermeiden
                                        Sync-PackageInfo $this $listbox
                                    }
                                }
                                Space = @{
                                    Control = "Panel"
                                    Height = 15
                                    Dock = "Top"
                                    BackColor = Get-Color "Transparent"
                                }
                                TabLabel = @{
                                    Control = "Label"
                                    Text = "Suchergebnisse"
                                    Font = Get-Font -Preset "TabLabel"
                                    Dock = "Bottom"
                                    ForeColor = Get-Color "Accent"
                                    Height = 20
                                    Visible = $false
                                }
                                SearchBox = @{
                                    Control         = "TextBox"
                                    Dock            = "Top"
                                    BackColor       = Get-Color "Accent"
                                    ForeColor       = Get-Color "Dark"
                                    Add_TextChanged = {
                                        param($searchBox, $e)
                                        $query = $searchBox.Text.Trim()
                                        if (-not ($searchBox.Tag -is [hashtable])) { $searchBox.Tag = @{} } # Sicherstellen, dass die Tag-Eigenschaft als Hashtable initialisiert ist, um spätere Fehler zu vermeiden

                                        # Vorhandenen Suchzeitgeber stoppen und entfernen, wenn die Suchanfrage geändert wird, um unnötige Suchen zu vermeiden
                                        Stop-Search -SearchBox $searchBox
                                        Stop-Timer -Timer $searchBox.Tag.SearchTimer

                                        Receive-Search -query $query -control $searchBox
                                        $token = $script:SearchToken
                                        
                                        # Suchzeitgeber erstellen, um die Suche um 300ms zu verzögern (debouncing)
                                        $timer = [Timer]::new()
                                        $timer.Interval = 300
                                        $timer.Tag = @{
                                            SearchBox = $searchBox
                                            Query     = $query
                                            TabList   = $searchBox.Parent.Controls["TabList"]
                                            TabLabel  = $searchBox.Parent.Controls["TabLabel"]
                                            InfoLabel = $searchBox.Parent.Controls["InfoLabel"]
                                            Token     = $token
                                        }

                                        # Ereignis-Handler für den Timer-Tick definieren
                                        $timer.Add_Tick({
                                            $this.Stop()
                                            if ( -not $this.Tag ) { return }
                                            else { $state = $this.Tag }
                                            $this.Dispose()
                                            
                                            
                                            $searchBox  = $state.SearchBox
                                            if ($searchBox.IsDisposed) { return }
                                            if (-not ($searchBox.Tag -is [hashtable])) { return }
                                            $searchBox.Tag.SearchTimer = $null

                                            $results = Search-Application -Query $state.Query -SearchToken $state.Token -SearchBox $searchBox -Time 15

                                            if ($state.Token -ne $script:SearchToken) { return }
                                            if ($searchBox.Text.Trim() -ne $state.Query) { return }

                                            $state.TabList.Items.Clear()
                                            if ($results.Count -gt 0) {
                                                [void]$state.TabList.Items.AddRange($results)
                                                $state.TabList.DisplayMember = "DisplayName"
                                                $state.TabLabel.Text = "$($results.Count) Pakete gefunden"
                                                $state.TabList.Visible = $true
                                                $state.TabLabel.Visible = $true
                                                $state.InfoLabel.Visible = $false
                                                Start-Search -SearchBox $searchBox -ListBox $state.TabList -Results $results -Token $state.Token
                                            } else {
                                                $state.TabList.Visible = $false
                                                $state.TabLabel.Visible = $false
                                                $state.InfoLabel.Text = "Keine Pakete gefunden."
                                                $state.InfoLabel.Visible = $true
                                            }
                                        })

                                        $searchBox.Tag.SearchTimer = $timer
                                        $timer.Start()
                                    }
                                }
                                SearchHeader = @{
                                    Control     = "Label"
                                    Text        = "Chocolatey Software"
                                    Dock        = "Top"
                                    Font        = Get-Font -Preset "SearchHeader"
                                    ForeColor   = Get-Color "Accent"
                                    Height      = 120
                                }
                                InfoLabel = @{
                                    Control     = "Label"
                                    Text        = "Gib den Namen eines Chocolatey-Paketes ein, um nach verfügbaren Paketen zu suchen."
                                    Dock        = "Bottom"
                                    Font        = Get-Font -Preset "LabelItalic"
                                    TextAlign   = "MiddleCenter"
                                    Height      = 50
                                }
                            }
                        }
                        SuggestedTab = @{
                            Control     = "TabPage"
                            Text        = "Vorschläge"
                            Controls    = @{
                                TabLabel = @{
                                    Control = "Label"
                                    Text    = "Keine Vorschläge verfügbar"
                                    Dock    = "Fill"
                                    Font    = Get-Font -Preset "TabLabel"
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
                            Text        = "Installiert"
                            Controls    = @{
                                TabLabel = @{
                                    Control = "Label"
                                    Visible = $true
                                    Text    = "Keine Pakete installiert"
                                    Dock    = "Fill"
                                    Font    = Get-Font -Preset "TabLabel"
                                }
                                TabList = @{
                                    Control     = "ListBox"
                                    Visible     = $false

                                    Add_SelectedIndexChanged = {
                                        param($listBox, $e)
                                        $itemCount      = $listBox.Items.Count
                                        $selectedItems  = $listBox.SelectedItems

                                        (Get-Control $this "UpdateButton").Visible      = $selectedItems.Count -gt 0
                                        (Get-Control $this "UninstallButton").Visible   = $selectedItems.Count -gt 0
                                        (Get-Control $this "SelectLabel").Text = if ($selectedItems.Count -eq $itemCount) { "Alle Abwählen" } else { "Alle Auswählen" }
                                    }
                                }
                            }
                        }
                    }
                    
                    # Events für TabControl definieren, um Daten zu laden und Steuerelemente entsprechend zu aktualisieren, wenn zwischen den Tabs gewechselt wird
                    Add_SelectedIndexChanged = {
                        param($src, $e)
                        Write-Debug "Tab gewechselt: $($src.SelectedTab.Text)"

                        # TabLabel und TabList des ausgewählten Tabs abrufen, um sie mit den entsprechenden Daten zu füllen
                        $tabLabel    = $src.SelectedTab.Controls["TabLabel"]
                        $tabList     = $src.SelectedTab.Controls["TabList"]
                        

                        # Lade die entsprechenden Daten, wenn der Tab gewechselt wird
                        switch ($src.SelectedTab.Name) {
                            "SearchTab" { return }
                            "SuggestedTab" {
                                if (-not $Cache.SuggestedPackages) {
                                    $tabLabel.Text = "Lade vorgeschlagene Chocolatey-Pakete..."
                                    $tabLabel.Visible = $true
                                    $Cache.SuggestedPackages = Get-SuggestedPackage
                                }
                                [void]$tabList.Items.AddRange($Cache.SuggestedPackages)
                                break
                            }
                            "PackagesTab" {
                                if (-not $Cache.InstalledPackages) {
                                    $tabLabel.Visible   = $true
                                    $tabLabel.Text      = "Lade installierte Chocolatey-Pakete..."
                                    # Cache mit installierten Paketen füllen
                                    $Cache.InstalledPackages = Get-Package
                                }
                                $Cache.InstalledPackages = $Cache.InstalledPackages | Sort-Object Name
                                [void]$tabList.Items.AddRange($Cache.InstalledPackages)
                                break
                            }
                        }
                        
                        # Sichtbarkeit der Steuerelemente anpassen
                        $tabLabel.Visible    = $false
                        $tabList.Visible     = $true
                        (Get-Control $this "SelectLabel").Visible = $true          
                    }
                    Add_Deselected = {
                        param($tabControl, $e)
                        $oldTab         = $e.TabPage
                        
                        # Buttons ausblenden
                        $sidebarPanel = Get-Control $this "SidebarPanel"
                        $sidebarPanel.Controls["UpdateButton"].Visible      = $false
                        $sidebarPanel.Controls["UninstallButton"].Visible   = $false
                        $sidebarPanel.Controls["InstallButton"].Visible     = $false
                        
                        # Paketdetails ausblenden
                        $packageInfo = $sidebarPanel.Controls["PackageInfo"]
                        $packageInfo.Controls["PackageInfoTitle"].Visible       = $false
                        $packageInfo.Controls["PackageInfoLabel"].Visible       = $false
                        $packageInfo.Controls["PackageInfoDescription"].Visible = $false

                        # Tab-spezifische Steuerelemente zurücksetzen
                        $this.Parent.Controls["SelectLabel"].Visible    = $false
                        $oldTab.Controls["TabLabel"].Visible            = $false
                        $oldTab.Controls["TabList"].Items.Clear()
                        $tabControl.Controls["SearchTab"].Controls["SearchBox"].Text = ""
                    }

                }
                SelectLabel = @{
                    Control     = "Label"
                    Text        = "Alle auswählen"
                    Height      = 30
                    Font        = Get-Font -Preset "LabelButton"
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
                    Font                = Get-Font -Preset "LabelItalic"
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
            Dock        = "Right"
            ForeColor   = Get-Color "Dark"
            BackColor   = Get-Color "Accent"
            Width       = 220
            Padding     = [Padding]::new(10,5,0,0)
            Controls    = [ordered]@{
                # Paketdetails
                PackageInfo = @{
                    Control         = "Panel"
                    Dock            = "Fill"
                    ForeColor       = Get-Color "Dark"
                    BackColor       = Get-Color "Accent"
                    Controls        = [ordered]@{
                        PackageInfoDescription = @{
                            Control         = "RichTextBox"
                            Text            = "Beschreibung."
                            Dock            = "Fill"
                            Font            = Get-Font -Preset "PackageInfoDescription"
                            BackColor       = Get-Color "Accent"
                            ForeColor       = Get-Color "Dark"
                            ReadOnly        = $true
                            Multiline       = $true
                            ScrollBars      = "Vertical"
                            BorderStyle     = "None"
                            DetectUrls      = $false
                            WordWrap        = $true
                            ShortcutsEnabled = $true
                            ToolTip         = "Paketbeschreibung (scrollbar)."
                            Visible         = $false
                        }
                        PackageInfoLabel = @{
                            Control             = "Label"
                            Text                = "Starte..."
                            Height              = 60
                            Font                = Get-Font -Preset "PackageInfoLabel" -Size 8 -Style "Bold"
                            Dock                = "Top"
                            TextAlign           = "TopCenter"
                            Visible             = $false
                        }
                        PackageInfoTitle = @{
                            Control     = "Label"
                            Text        = "DisplayName."
                            Dock        = "Top"
                            TextAlign   = "MiddleCenter"
                            Font        = Get-Font -Preset "PackageInfoTitle"
                            Height      = 30
                            Visible     = $false

                            Add_TextChanged = {
                                # Dynamische Anpassung der Schriftgröße basierend auf der Länge des Titels, damit lange Namen besser lesbar sind, ohne die Übersicht zu verlieren
                                if ($this.Text.Length -le 15) {
                                    $this.Height = 30
                                    $this.Font = Get-Font -Preset "PackageInfoTitle" -Size 12
                                } elseif ($this.Text.Length -le 30) {
                                    $this.Height = 40
                                    $this.Font = Get-Font -Preset "PackageInfoTitle" -Size 11
                                } else {
                                    $this.Height = 50
                                    $this.Font = Get-Font -Preset "PackageInfoTitle" -Size 10
                                }
                            }
                        }
                    }
                }
                # Chocolatey entfernen
                UninstallChocoButton = @{
                    Control     = "Button"
                    Text        = "Chocolatey entfernen"
                    Font        = Get-Font -Preset "SidebarButton"
                    Dock        = "Top"
                    Visible     = $false
                    Add_Click   = { 
                        Uninstall-Chocolatey { param($msg, [switch]$Final) Update-Status -Label (Get-Control $this "ProcessLabel") -Message $msg -Delay 2 -Final:$Final }
                    }
                }
                # Chocolatey hinzufügen
                InstallChocoButton = @{
                    Control     = "Button"
                    Text        = "Chocolatey hinzufügen"
                    Font        = Get-Font -Preset "SidebarButton"
                    Dock        = "Top"
                    Visible     = $false
                    Add_Click   = { 
                        Install-Chocolatey { param($msg, [switch]$Final) Update-Status -Label (Get-Control $this "ProcessLabel") -Message $msg -Delay 2 -Final:$Final }
                    }
                }
                # Chocolatey-Version
                VersionLabel = @{
                    Control     = "Label"
                    Text        = "Version: "
                    Font        = Get-Font -Preset "SidebarVersion"
                    Dock        = "Top"
                    Height      = 30
                    TextAlign   = "TopCenter"
                }
                # Chocolatey-Titel
                NameLabel = @{
                    Control     = "Label"
                    Text        = "Chocolatey"
                    Font        = Get-Font -Preset "SidebarTitle"
                    Dock        = "Top"
                    Height      = 30
                }

                # Pakete aktualisieren Button
                UpdateButton = @{
                    Control     = "Button"
                    Text        = "Aktualisieren"
                    Font        = Get-Font -Preset "SidebarButton"
                    Dock        = "Bottom"
                    Visible     = $false
                    Add_Click   = { 
                        $NewStatus          = { param($msg, [switch]$Final) Update-Status -Label (Get-Control $this "ProcessLabel") -Message $msg -Delay 2 -Final:$Final }
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
                    Text        = "Installieren"
                    Font        = Get-Font -Preset "SidebarButton"
                    Dock        = "Bottom"
                    Visible     = $false
                    Add_Click   = { 
                        Write-Debug "[EVENT] InstallButton Clicked | Starte Installation der ausgewählten Pakete"
                        $selectedTab        = (Get-Control $this "TabControl").SelectedTab # Aktuellen Tab abrufen
                        $tabList            = $selectedTab.Controls["TabList"] # TabList des aktuellen Tabs abrufen, um die ausgewählten Pakete zu ermitteln
                        $checkBox           = $tabList.GetType().Name -eq "CheckedListBox" # Überprüfen, ob es sich um eine CheckedListBox handelt, um die Auswahl entsprechend zu verarbeiten (CheckedItems vs SelectedItems)
                        $selectedPackages   = if ($checkBox) { @($tabList.CheckedItems) } else { @($tabList.SelectedItems) }
                        
                        if ($selectedPackages.Count -eq 0) { return }
                        elseif ($selectedPackages.Count -gt 1) { & $UpdateLabel "Installiere ausgewählte Chocolatey-Pakete..." }
                        $tabList.ClearSelected() # unsafe

                        # Installationsprozess für jedes ausgewählte Paket starten und den Fortschritt aktualisieren, um den Benutzer über den aktuellen Status zu informieren; bei CheckBoxen die Häkchen entfernen, damit der Benutzer sofort sieht, welche Pakete bereits in Bearbeitung sind
                        foreach ($package in $selectedPackages) { 
                            & $UpdateLabel "Installiere $($package.Name)..."

                            $SuccessInstall = Install-Application -Name $package.Id
                            if ($SuccessInstall) {
                                & $UpdateLabel "'$($package.Name)' erfolgreich installiert."

                                # Cache aktualisieren
                                if ($Cache.InstalledPackages) { $Cache.InstalledPackages += $package }
                            } else {
                                & $UpdateLabel "Fehler beim Installieren von '$($package.Name)'."
                            }
                            if ($checkBox) { $tabList.SetItemChecked($tabList.Items.IndexOf($package), $false) }
                        }
                        
                        & $UpdateLabel "Installation abgeschlossen." -Final
                    }
                }
                # Pakete deinstallieren Button
                UninstallButton = @{
                    Control     = "Button"
                    Text        = "Deinstallieren"
                    Font        = Get-Font "SidebarButton"
                    Dock        = "Bottom"
                    Visible     = $false
                    Add_Click   = { 
                        $selectedTab        = (Get-Control $this "TabControl").SelectedTab
                        $tabList            = $selectedTab.Controls["TabList"]
                        $selectedPackages   = @($tabList.SelectedItems)

                        if ($selectedPackages.Count -eq 0) { return }
                        elseif ($selectedPackages.Count -gt 1) {
                            $confirmation = Show-MessageBox "UninstallPackagesConfirm" # Bestätigungsdialog anzeigen, um unbeabsichtigte Massen-Deinstallationen zu vermeiden
                            if (-not $confirmation) { return }
                            & $UpdateLabel "Deinstalliere ausgewählte Chocolatey-Pakete..."
                        }

                        foreach ($package in $selectedPackages) {
                            & $UpdateLabel "Deinstalliere $($package.Name)..."
                            
                            # Deinstallationsprozess für jedes ausgewählte Paket starten und den Fortschritt aktualisieren, um den Benutzer über den aktuellen Status zu informieren
                            $SuccessfulUninstall = Uninstall-Application -Name $package.Name
                            if ($SuccessfulUninstall) {
                                $tabList.Items.Remove($package)
                                & $UpdateLabel "'$($package.Name)' erfolgreich deinstalliert."
                                
                                # Cache aktualisieren
                                if ($Cache.InstalledPackages) { $Cache.InstalledPackages = $Cache.InstalledPackages | Where-Object { $_.Name -ne $package.Name } }
                            } else {
                                & $UpdateLabel "Fehler beim Deinstallieren von '$($package.Name)'."
                                Show-MessageBox "UninstallPackageFailed" -Args $package.Name
                            }
                        }

                        # Abschließende Statusmeldung basierend auf dem Erfolg oder Fehler der Deinstallation anzeigen, um den Benutzer über das Ergebnis zu informieren
                        & $UpdateLabel "Deinstallation abgeschlossen." -Final; Show-MessageBox "UninstallPackagesFinished" 
                    }
                }
            }
        }
    }
    Events      = @{
        Load = {
            Write-Information "Initialisiere Chocolatey-Modul..."
            $Cache.IsInstalled = Test-Installation
            $Cache.Version = if ($Cache.IsInstalled) { Get-Version } else { $null }

        }
        Shown = {
            $versionLabel = (Get-Control $this "VersionLabel")

            # Chocolatey-Installationsstatus prüfen und entsprechende Steuerelemente anzeigen
            Write-Information "Prüfe Chocolatey-Installationsstatus..."

            if (-not $Cache.IsInstalled) {
                $versionLabel.Text += "Nicht installiert"                   # Hinweis auf fehlende Installation
                (Get-Control $this "InstallChocoButton").Visible = $true    # Chocolatey installieren Button anzeigen 
                $tabControl = (Get-Control $this "TabControl")
                foreach ($tab in $tabControl.TabPages) {
                    if ($tab.Name -ne "SuggestedTab") { $tab.Enabled = $false } # Alle Tabs außer "Vorschläge" deaktivieren, da sie ohne Installation nicht sinnvoll sind
                }
            } else {
                $versionLabel.Text += $Cache.Version # Chocolatey-Version anzeigen
                (Get-Control $this "UninstallChocoButton").Visible  = $true # Chocolatey deinstallieren Button anzeigen
            }

            (Get-Control $this "SearchBox").Focus() # Fokus auf Suchbox setzen
        }
    }
}

<# CHOCOLATEY FUNCTIONS #>
function Install-Chocolatey {
    Write-Information "Starte Installation von Chocolatey..."

    # Ausführunagsrichtlinien anpassen (erlaubt für diesen Prozess unsignierte Skripte)
    Write-Information "Setze Ausführungsrichtlinie auf Bypass für diesen Prozess..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    
    # Sicherheitsprotokoll anpassen (benötigt für TLS 1.2, das von Chocolatey-Servern verwendet wird)
    Write-Information "Aktualisiere Sicherheitsprotokolle für Webanfragen..."
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    
    # Chocolatey laden und installieren (Setup durch Chocolatey-Installationsskript)
    Write-Information "Lade und installiere Chocolatey..."
    Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -UseBasicParsing | Invoke-Expression

    # Überprüfen, ob die Installation erfolgreich war
    if (Test-Chocolatey) {
        Write-Information "Chocolatey wurde erfolgreich installiert."
        Show-MessageBox "InstallChocolateySuccess"
    } else {
        Write-Warning "Fehler: Chocolatey konnte nicht installiert werden."
        Show-MessageBox "InstallChocolateyFailed"
    }
}
function Uninstall-Chocolatey {
    # Bestätigung der Deinstallation einholen
    $confirm = Show-MessageBox "ConfirmUninstallChocolatey"
    if (-not $confirm) { Write-Information "Deinstallation von Chocolatey abgebrochen."; return }

    # Umgebungsvariable für Chocolatey-Installation überprüfen
    Write-Information "Überprüfe Chocolatey-Installation und PATH-Variablen..."
    if (-not $env:ChocolateyInstall) { 
        Write-Information "Chocolatey ist nicht installiert oder die Umgebungsvariable fehlt."
        return
    }

    # Umgebungsvariable für Chocolatey-Installation überprüfen
    Write-Information "Überprüfe Chocolatey-Installation und PATH-Variablen..."
    if (-not $env:ChocolateyInstall) { 
        Write-Information "Chocolatey ist nicht installiert oder die Umgebungsvariable fehlt."
        return 
    }
    if (-not (Test-Path $env:ChocolateyInstall)) { 
        Write-Information "Keine Chocolatey-Installation unter '$env:ChocolateyInstall' gefunden."
        Write-Information "Keine weitere Verarbeitung notwendig."
        return 
    }

    <#
        Hier werden bewusst die .NET-Registry-Aufrufe verwendet, um in PATH-Werten eingebettete
        Umgebungsvariablen zu erhalten. Der PowerShell-Registry-Provider bietet keine Möglichkeit,
        Variablenreferenzen unverändert beizubehalten. Wir möchten vermeiden, dass diese versehentlich
        durch absolute Pfadangaben überschrieben werden.

        Während die Registry beispielsweise "%SystemRoot%" in einem PATH-Eintrag anzeigt,
        sieht der PowerShell-Registry-Provider lediglich "C:\Windows".
    #>
    Write-Information "Lese aktuelle PATH-Variablen aus der Registry..."
    $userKey  = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
    $userPath = $userKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()

    Write-Information "Öffne Registry-Schlüssel für PATH-Variablen..."
    $machineKey  = [Registry]::LocalMachine.OpenSubKey('SYSTEM\ControlSet001\Control\Session Manager\Environment\', $true)
    $machinePath = $machineKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()
    
    Write-Information "Sichere aktuelle PATH-Variablen..."
    $backupFile  = "C:\PATH_backups_ChocolateyUninstall.txt"
    $backupPATHs = @( "User PATH: $userPath", "Machine PATH: $machinePath" )
    $backupPATHs | Set-Content -Path $backupFile -Encoding UTF8 -Force

    # Chocolatey-Installationspfad aus PATH entfernen, falls vorhanden
    Write-Information "Bereinige PATH-Variablen von Chocolatey-Installationspfad..."
    if ($userPath -like "*$env:ChocolateyInstall*") {
        Write-Information "Chocolatey-Installationspfad im Benutzer-PATH gefunden. Wird entfernt..."

        $newUserPATH = @(
            $userPath -split [System.IO.Path]::PathSeparator |
            Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }
        ) -join [System.IO.Path]::PathSeparator

        # NEVER use [Environment]::SetEnvironmentVariable() for PATH values; see https://github.com/dotnet/corefx/issues/36449
        # This issue exists in ALL released versions of .NET and .NET Core as of 12/19/2019
        $userKey.SetValue('PATH', $newUserPATH, 'ExpandString')
    }
    if ($machinePath -like "*$env:ChocolateyInstall*") {
        Write-Information "Chocolatey-Installationspfad im System-PATH gefunden. Wird entfernt..."

        $newMachinePATH = @(
            $machinePath -split [System.IO.Path]::PathSeparator |
            Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }
        ) -join [System.IO.Path]::PathSeparator

        # NEVER use [Environment]::SetEnvironmentVariable() for PATH values; see https://github.com/dotnet/corefx/issues/36449
        # This issue exists in ALL released versions of .NET and .NET Core as of 12/19/2019
        $machineKey.SetValue('PATH', $newMachinePATH, 'ExpandString')
    }

    # Anpassung für Dienste, die in Unterordnern von ChocolateyInstall ausgeführt werden
    $agentService = Get-Service -Name chocolatey-agent -ErrorAction SilentlyContinue
    if ($agentService -and $agentService.Status -eq 'Running') {
        Write-Information "Stoppe Dienst: chocolatey-agent..."
        $agentService.Stop()
    }
    # TODO: Weitere relevante Dienste hier ergänzen
    Write-Information "Lösche Chocolatey-Installationsverzeichnis..."
    Remove-Item -Path $env:ChocolateyInstall -Recurse -Force

    'ChocolateyInstall', 'ChocolateyLastPathUpdate' | ForEach-Object {
        foreach ($scope in 'User', 'Machine') { 
            [Environment]::SetEnvironmentVariable($_, [string]::Empty, $scope)
        }
    }

    Write-Information "Schließe Registry-Schlüssel..."
    $machineKey.Close()
    $userKey.Close()
    if ($env:ChocolateyToolsLocation -and (Test-Path $env:ChocolateyToolsLocation)) { Remove-Item -Path $env:ChocolateyToolsLocation -Recurse -Force }

    foreach ($scope in 'User', 'Machine') { [Environment]::SetEnvironmentVariable('ChocolateyToolsLocation', [string]::Empty, $scope) }
    Write-Information "Deinstallation von Chocolatey abgeschlossen."

    # Mitteilung an den Benutzer abschließen
    Show-MessageBox "UninstallChocolateySuccess"
}
function Test-Installation {
    Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name)"

    # Cache-Wert zurückgeben, wenn bereits ermittelt, um wiederholte Überprüfungen zu vermeiden
    if ($null -ne $Cache.IsInstalled) { 
        Write-Debug "[CACHE] $($MyInvocation.MyCommand.Name) | Gefundener Cache-Wert: $($Cache.IsInstalled)"
        return $Cache.IsInstalled 
    }

    # Überprüfen, ob der Befehl "choco" verfügbar ist, um die Installation von Chocolatey zu bestätigen
    Write-Debug "[CHECK] $($MyInvocation.MyCommand.Name) | Überprüfe Verfügbarkeit des 'choco'-Befehls zur Bestätigung der Installation"
    $cmd = Get-Command choco -ErrorAction SilentlyContinue
    if (-not $cmd) { 
        Write-Debug "[CHECK] $($MyInvocation.MyCommand.Name) | 'choco'-Befehl nicht gefunden"
        Write-Information "Chocolatey ist nicht installiert oder nicht im PATH verfügbar."

        # Cache aktualisieren, um zukünftige Aufrufe zu optimieren, und Rückgabewert festlegen
        $Cache.IsInstalled = $false
        
        # Rückgabewert false zurückgeben, um anzuzeigen, dass Chocolatey nicht installiert ist
        Write-Debug "[EXIT] $($MyInvocation.MyCommand.Name) | Chocolatey-Installation nicht bestätigt."
        return $false
    } 

    # Rückgabewert true zurückgeben, um anzuzeigen, dass Chocolatey installiert ist, und Cache aktualisieren, um zukünftige Aufrufe zu optimieren
    Write-Debug "[EXIT] $($MyInvocation.MyCommand.Name) | Chocolatey-Installation bestätigt."
    $Cache.IsInstalled = $true
    return $true
}
function Get-Version {
    Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name)"

    # Cache-Wert zurückgeben, wenn bereits ermittelt, um wiederholte Aufrufe zu optimieren
    if ($null -ne $Cache.Version) { 
        Write-Debug "[CACHE] $($MyInvocation.MyCommand.Name) | Gefundener Cache-Wert: $($Cache.Version)"
        return $Cache.Version 
    }

    # Überprüfen, ob Chocolatey installiert ist, bevor die Version abgefragt wird, um Fehler zu vermeiden
    Write-Debug "[CHECK] $($MyInvocation.MyCommand.Name) | Überprüfe Chocolatey-Installation vor Versionsermittlung"
    if (-not $Cache.IsInstalled) { Write-Debug "[EXIT] $($MyInvocation.MyCommand.Name) | Chocolatey ist nicht installiert."; return $null }

    # Version abrufen und im Cache speichern, um zukünftige Aufrufe zu beschleunigen
    Write-Debug "[INFO] $($MyInvocation.MyCommand.Name) | Rufe Chocolatey-Version ab..."
    $version = (& choco --version).Trim()

    Write-Debug "[EXIT] $($MyInvocation.MyCommand.Name) | Version: $version"
    $Cache.Version = $version
    return $version
}

function Get-Package {
    Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name)"

    # Cache-Wert zurückgeben, wenn bereits ermittelt, um wiederholte Aufrufe zu optimieren
    if ($Cache.InstalledPackages) {
        Write-Debug "[CACHE] $($MyInvocation.MyCommand.Name) | Gefundener Cache-Wert: $($Cache.InstalledPackages.Count) Pakete"
        return $Cache.InstalledPackages
    } 

    # Standardwert zurückgeben, um die Konsistenz der Rückgabedaten zu gewährleisten, falls keine Pakete gefunden werden oder ein Fehler auftritt
    $Packages = @{
        Name    = "Keine Pakete gefunden"
        Version = ""
    }

    # Überprüfen, ob Chocolatey installiert ist, bevor versucht wird, Pakete abzurufen, um Fehler zu vermeiden
    Write-Debug "[CHECK] $($MyInvocation.MyCommand.Name) | Überprüfe Chocolatey-Installation vor Paketabruf"
    if (-not $Cache.IsInstalled) { return @($Packages) }

    # Alle installierten Pakete mit Name und Version abrufen, um sie in der Benutzeroberfläche anzuzeigen
    $list           = choco list --limitoutput
    $packageList    = foreach ($package in $list) {
        $name, $version = $package -split '\|' 
        [PSCustomObject]@{
            Name    = $name
            Version = $version
        }
    }
    $Packages = $packageList | Sort-Object Name
    Write-Debug "[EXIT] $($MyInvocation.MyCommand.Name) | Gefundene Pakete: $($Packages.Count)"
    $Cache.InstalledPackages = $Packages
    return @($Packages)
}
function Get-SuggestedPackage {
    Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name)"

    # Cache-Wert zurückgeben, wenn bereits ermittelt, um wiederholte Aufrufe zu optimieren
    if ($Cache.SuggestedPackages) {
        Write-Debug "[CACHE] $($MyInvocation.MyCommand.Name) | Gefundener Cache-Wert: $($Cache.SuggestedPackages.Count) Pakete"
        return $Cache.SuggestedPackages
    }

    # Standardwert zurückgeben, um die Konsistenz der Rückgabedaten zu gewährleisten, falls keine Vorschläge gefunden werden oder ein Fehler auftritt
    $Packages = @{
        Name    = "Keine Vorschläge gefunden"
        Version = ""
    }

    # Überprüfen, ob Chocolatey installiert ist, bevor versucht wird, Vorschläge abzurufen, um Fehler zu vermeiden
    Write-Debug "[CHECK] $($MyInvocation.MyCommand.Name) | Überprüfe Chocolatey-Installation vor Vorschlagsabruf"
    if (-not $Cache.IsInstalled) { return @($Packages) }

    $suggestedPackages = [ordered]@{
        # Packagename bei Chocolatey | Anzeigename
        "7zip"                      = "7-Zip"
        "adb"                       = "Android Debug Bridge (ADB)"
        "adobereader"               = "Adobe Acrobat Reader DC"
        "autoruns"                  = "Autoruns"
        "bitwarden"                 = "Bitwarden"
        "discord"                   = "Discord"
        "dropbox"                   = "Dropbox"
        "filezilla"                 = "FileZilla"
        "googlechrome"              = "Google Chrome"
        "googledrive"               = "Google Drive"
        "greenshot"                 = "Greenshot"
        "kate"                      = "Kate"
        "keepassxc"                 = "KeePassXC"
        "firefox"                   = "Mozilla Firefox"
        "thunderbird"               = "Mozilla Thunderbird"
        "onedrive"                  = "OneDrive"
        "qbittorrent"               = "qBittorrent"
        "powerstoys"                = "PowerToys"
        "putty"                     = "PuTTY"
        "python3"                   = "Python 3.x"
        "scrcpy"                    = "scrcpy"
        "signal"                    = "Signal"
        "sshfs"                     = "SSHFS-Win"
        "steam"                     = "Steam"
        "teamspeak"                 = "TeamSpeak 3"
        "teamviewer-qs"             = "Teamviewer QuickSupport"
        "wingetui"                  = "UniGetUI"
        "ventoy"                    = "Ventoy"
        "virtualbox"                = "VirtualBox"
        "visualstudio2019buildtools"= "Visual Studio 2019 Build Tools"
        "visualstudio2019community" = "Visual Studio 2019 Community"
        "vscode"                    = "Visual Studio Code"
        "vlc"                       = "VLC media player"
        "winget"                    = "WinGet"
        "winfsp"                    = "WinFsp"
        "winrar"                    = "WinRAR"
        "winscp"                    = "WinSCP"
    }
    $Packages = foreach ($key in $suggestedPackages.Keys) {
        [PSCustomObject]@{
            Id   = $key
            Name = $suggestedPackages[$key]
        }
    }
    
    Write-Debug "[EXIT] $($MyInvocation.MyCommand.Name) | Gefundene Vorschläge: $($Packages.Count)"
    $Cache.SuggestedPackages = $Packages
    return @($Packages)
}




<# SEARCH #>
function Start-Search {
    param(
        [System.Windows.Forms.TextBox]$SearchBox,
        [System.Windows.Forms.ListBox]$ListBox,

        [object[]]$Results,
        [string]$Token,
        [int]$SearchDuration = 12000
    )
    Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name) | Params: SearchBox='$($SearchBox.Name)', ListBox='$($ListBox.Name)', ResultsCount=$($Results.Count), Token='$Token', SearchDuration=$SearchDuration"

    # Sicherstellen, dass die Steuerelemente gültig sind
    if (-not (Test-Control $SearchBox)) { return }
    if (-not (Test-Control $ListBox))   { return }

    # Sicherstellen, dass das Suchfeld über die erwarteten Tag-Strukturen verfügt
    if (-not ($SearchBox.Tag -is [hashtable])) { $SearchBox.Tag = @{} }

    # Beenden laufender Suchvorgänge und Titelanreicherungen, um Konflikte zu vermeiden
    Stop-Search -SearchBox $SearchBox

    # Ergebnisse in die Warteschlange einfügen
    $queue = [System.Collections.Queue]::new()
    foreach ($result in $Results) { $queue.Enqueue($result) } # Ergebnisse in die Warteschlange einfügen, um sie schrittweise anzuzeigen und die Benutzeroberfläche reaktionsfähig zu halten, insbesondere bei großen Ergebnislisten

    # Timer für die schrittweise Anzeige von Suchergebnissen einrichten
    Stop-Timer -Control $SearchBox -Name "TitleEnrichmentTimer" # Sicherstellen, dass kein vorheriger Timer mit demselben Namen existiert, um Konflikte zu vermeiden
    $TitleEnrichmentTimer = Set-Timer -Context @{
        ListBox         = $ListBox
        SearchBox       = $SearchBox
        Queue           = $queue
        Token           = $Token
        SearchDuration  = $SearchDuration
    } -Action {
        if ($null -eq $this.Tag) { Stop-Timer -Timer $this; return }
        $State      = $this.Tag
        $searchBox  = $State.SearchBox
        $listBox    = $State.ListBox
        $queue      = $State.Queue
        $token      = $State.Token
        $duration   = $State.SearchDuration
        
        # Sicherstellen, dass die Steuerelemente noch gültig sind
        if ($searchBox.IsDisposed -or $listBox.IsDisposed) { $this.Stop(); $this.Dispose(); return }
        if ($token -ne $script:SearchToken -or (Test-Empty $searchBox.Text)) { Stop-Search -SearchBox $searchBox; return }
        

        # Überprüfen, ob bereits ein laufender Prozess für die Titelanreicherung existiert, um Konflikte zu vermeiden
        $activeLookup = $searchBox.Tag.TitleLookup
        if ($activeLookup) {

            # Überprüfen, ob die maximale Suchdauer überschritten wurde, um endlose Prozesse zu vermeiden
            $elapsed = [int]([System.DateTime]::UtcNow - $activeLookup.StartedAt).TotalMilliseconds
            if ($elapsed -ge $duration) {
                try { 
                    if (-not $activeLookup.Process.HasExited) {
                        $activeLookup.Process.Kill()
                        [void]$activeLookup.Process.WaitForExit(500)
                    }
                } catch {  
                } finally {
                    $activeLookup.Process.Dispose()
                    $searchBox.Tag.TitleLookup = $null
                }
                return
            }

            # Schutz gegen unbeabsichtigte Auslösung während der Aktualisierung der Liste
            if ( -not $activeLookup.Process.HasExited ) { return }

            try {
                [void]$activeLookup.Process.WaitForExit()
                
                $stdErr = $activeLookup.StdErrTask.GetAwaiter().GetResult()
                $stdout = $activeLookup.StdOutTask.GetAwaiter().GetResult() # Standardausgabe des Prozesses abrufen, um die Details des Pakets zu extrahieren
                if (Test-Fill $stdErr) { Write-Warning "Fehler beim Abrufen der Anwendungsdetails für '$($activeLookup.PackageId)': $stdErr" }
                $details = ConvertFrom-ChocolateyInfoText -Text $stdout -Name $activeLookup.PackageId -FallbackVersion $activeLookup.PackageVersion
                if ($details) {
                    $Cache.PackageDetails[$details.Id] = $details # Details im Cache speichern, um zukünftige Abrufe zu beschleunigen
                    Update-ListBox -ListBox $listBox -Package $details
                } 
            } catch {
            } finally {
                $activeLookup.Process.Dispose()
                $searchBox.Tag.TitleLookup = $null
            }
            return
        }

        if ($queue.Count -eq 0) { Stop-Timer -Control $searchBox -Name "TitleEnrichmentTimer"; return }

        $package = $queue.Dequeue()
        $cachedDetails = if ($Cache.PackageDetails.ContainsKey($package.Id)) { $Cache.PackageDetails[$package.Id] } else { $null }
        if ($cachedDetails) { Update-ListBox -ListBox $listBox -Package $cachedDetails; return }

        try {
            $process = Start-ShellProcess (Get-Command choco -ErrorAction Stop).Source "info `"$($package.Id)`""

            $searchBox.Tag.TitleLookup = @{
                Process         = $process
                StdOutTask      = $process.StandardOutput.ReadToEndAsync()
                StdErrTask      = $process.StandardError.ReadToEndAsync()
                PackageId       = $package.Id
                PackageVersion  = $package.Version
                StartedAt       = [System.DateTime]::UtcNow
            }
        } catch {
            $searchBox.Tag.TitleLookup = $null
        }
    }
    Start-Timer -Timer $TitleEnrichmentTimer -Control $SearchBox -Name "TitleEnrichmentTimer" 
}
function Stop-Search {
    param( [System.Windows.Forms.TextBox]$SearchBox )

    # Sicherstellen, dass das Suchfeld gültig ist und über die erwarteten Tag-Strukturen verfügt
    if (-not (Test-Control $SearchBox))         { return }
    if (-not ($SearchBox.Tag -is [hashtable]))  { return }

    # Timer für die schrittweise Anzeige von Suchergebnissen stoppen und bereinigen
    Stop-Timer -Timer $SearchBox.Tag.TitleEnrichmentTimer

    # Laufenden Prozess für die Titelanreicherung beenden, falls vorhanden
    Stop-Lookup -SearchBox $SearchBox
}
function Receive-Search {
    param ( [string]$query, [System.Windows.Forms.Control]$control )
    $searchTab  = Get-Control $control "SearchTab"
    if (-not (Test-Control $searchTab)) { return }

    # Suchheader nur anzeigen, wenn die Suchanfrage leer ist
    $searchTab.Controls["SearchHeader"].Visible = $query.Length -lt 1 

    $searchTab.Controls["TabLabel"].Visible  = $false    # TabLabel ausblenden
    $searchTab.Controls["TabList"] | ForEach-Object { $_.Visible = $false; $_.Items.Clear() } # TabList leeren und ausblenden
    $searchTab.Controls["InfoLabel"].Visible = $true

    switch ($query.Length) {
        0 { $searchTab.Controls["InfoLabel"].Text = "Gib den Namen eines Chocolatey-Paketes ein, um nach verfügbaren Paketen zu suchen."; break }
        default { $searchTab.Controls["InfoLabel"].Text = "Suche nach '$query'..."; break }
    }

    # Token aktualisieren, um veraltete Suchergebnisse zu ignorieren, wenn die Suchanfrage geändert wird
    $script:SearchToken = [guid]::NewGuid().ToString("N")
}
function Update-ListBox {
    param ( [System.Windows.Forms.ListBox]$ListBox, $Package )
    
    # Sicherstellen, dass die Steuerelemente gültig sind und die Paketinformationsdaten vorhanden sind, um Fehler zu vermeiden
    if (-not (Test-Control $ListBox) -or (Test-Empty $Package)) { return }

    # Zielindex ermitteln, um das entsprechende Listenelement zu aktualisieren
    foreach ($item in $ListBox.Items) { 
        if ($item.Id -eq $Package.Id) { 
            $targetIndex = $ListBox.Items.IndexOf($item)
            break 
        } 
    }
    if ($targetIndex -lt 0) { return }

    # Sicherstellen, dass das ListBox-Tag über die erwarteten Strukturen verfügt, um die Unterdrückung von SelectionChanged-Ereignissen zu ermöglichen, damit die Aktualisierung der Listeneinträge nicht zu unerwünschten Seiteneffekten führt
    if ($ListBox.Tag -isnot [hashtable]) { $ListBox.Tag = @{} }
    $ListBox.Tag.SuppressSelectionChanged = $true

    try {
        $selectedIds    = @($ListBox.SelectedItems | ForEach-Object { $_.Id })
        $topIndex       = if ($ListBox.Items.Count -gt 0) { $ListBox.TopIndex } else { 0 }

        $existingItem = $ListBox.Items[$targetIndex]

        $updatedPackage = [PSCustomObject]@{
            Id           = $Package.Id
            Name         = if ($Package.Name)    { $Package.Name } else { $Package.Id }
            Version      = if ($Package.Version) { $Package.Version } else { $existingItem.Version }
            Title        = $Package.Title
            Published    = $Package.Published
            Authors      = $Package.Authors
            Tags         = $Package.Tags
            Summary      = $Package.Summary
            Description  = $Package.Description
            SoftwareSite = $Package.SoftwareSite
            DisplayName  = if ($Package.Title) { $Package.Title } elseif ($Package.Name) { $Package.Name } else { $Package.Id }
            Raw          = $existingItem.Raw # Vorhandene Rohdaten beibehalten, da sie möglicherweise zusätzliche Informationen enthalten, die nicht in den aktualisierten Paketdetails enthalten sind
        }


        $ListBox.Items.RemoveAt($targetIndex)
        [void]$ListBox.Items.Insert($targetIndex, $updatedPackage)
        $ListBox.DisplayMember = "DisplayName"

        if ($ListBox.Items.Count -gt 0) {
            $ListBox.TopIndex = [Math]::Min($topIndex, $ListBox.Items.Count - 1)
        }
        for ($index = 0; $index -lt $ListBox.Items.Count; $index++) {
            if ($selectedIds -contains $ListBox.Items[$index].Id -and -not $ListBox.GetSelected($index)) {
                $ListBox.SetSelected($index, $true)
            }
        }
    } finally {
        if ($ListBox.Tag -is [hashtable]){ $ListBox.Tag.SuppressSelectionChanged = $false }
    }
}




<# LOOKUP #>
function Stop-Lookup {
    param( [System.Windows.Forms.TextBox]$SearchBox )

    if (-not (Test-Control $SearchBox)) { return }
    if (-not ($SearchBox.Tag -is [hashtable])) { return }

    if ($SearchBox.Tag.ContainsKey("TitleLookup") -and $SearchBox.Tag.TitleLookup) {
        $lookup = $SearchBox.Tag.TitleLookup
        if ($lookup.Process) {
            try { if (-not $lookup.Process.HasExited) { Stop-ShellProcess -Process $lookup.Process } } 
            catch {} 
            finally { $lookup.Process.Dispose() }
        }
        $SearchBox.Tag.TitleLookup = $null
    }
}

<# APPLICATION #>
function Search-Application {
    param( 
        [string]$Query,         # Suchbegriff für die Paketsuche
        [int]$Time = 15,        # Dauer der Suche in Sekunden
        [string]$SearchToken,   # Token zur Identifikation der aktuellen Suche (z.B. für Abbruchbedingungen)

        [System.Windows.Forms.TextBox]$SearchBox  # TextBox-Steuerelement für die Sucheingabe
    )
    Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name) | Params: `$Query='$Query', `$Time=$Time, `$SearchToken='$SearchToken', `$SearchBox=$($SearchBox.Name)"

    # Überprüfen, ob Chocolatey installiert ist, bevor die Suche gestartet wird
    Write-Debug "[CHECK] $($MyInvocation.MyCommand.Name) | Überprüfe Chocolatey-Installation vor Suche mit Query '$Query'"
    if (-not $Cache.IsInstalled) { 
        if (Test-Installation) {
            Write-Debug "[UPDATE] $($MyInvocation.MyCommand.Name) | Aktualisiere Cache: Chocolatey-Installation bestätigt"
            $Cache.IsInstalled = $true
            Write-Information "Chocolatey-Installation bestätigt. Suche kann gestartet werden."
        } else {
            Write-Debug "[EXIT] $($MyInvocation.MyCommand.Name) | Chocolatey-Installation nicht bestätigt. Suche abgebrochen."
            Write-Warning "Chocolatey ist nicht installiert. Suche kann nicht durchgeführt werden."
            return @() 
        }
    }
    
    Write-Information "Suche nach Chocolatey-Paketen mit Query: $Query"
    $startedAt = [System.DateTime]::UtcNow
    try {
        # Prozess für die Suche starten 
        $process = Start-ShellProcess (Get-Command choco -ErrorAction Stop).Source "search `"$Query`" --limit-output"
        $stdOutTask = $process.StandardOutput.ReadToEndAsync()
        $stdErrTask = $process.StandardError.ReadToEndAsync()

        # Prozess überwachen und Ergebnisse sammeln, bis die Suche abgeschlossen ist oder die Zeit abgelaufen ist
        while (-not $process.HasExited) {

            Start-Sleep -Milliseconds 60  # Kurze Pause, um CPU-Last zu reduzieren
            if ("System.Windows.Forms.Application" -as [type]) { [Application]::DoEvents() } # UI-Thread responsive halten

            # Überprüfe die Dauer der Suche
            $timeNow     = [System.DateTime]::UtcNow
            $elapsedTime = [int]($timeNow - $startedAt).TotalSeconds
            if ($elapsedTime -ge $Time) {
                Stop-ShellProcess -Process $process
                Write-Debug "[TIMEOUT] $($MyInvocation.MyCommand.Name) | Suche nach '$Query' wurde nach $elapsedTime Sekunden abgebrochen."
                Write-Warning "Suche nach '$Query' wurde nach $Time Sekunden beendet (Timeout)."
                return @()
            }

            # Suche abbrechen, wenn die Suchanfrage im Suchfeld geändert wurde
            if ($SearchBox -and -not $SearchBox.IsDisposed -and $SearchBox.Text.Trim() -ne $Query) {
                Stop-ShellProcess -Process $process
                Write-Debug "[ABORT] $($MyInvocation.MyCommand.Name) | Suche nach '$Query' wurde abgebrochen, da die Suchanfrage geändert wurde."
                return @()
            }
            
        }
        
        # Fehlerausgabe protokollieren, falls vorhanden
        $stdErr = $stdErrTask.GetAwaiter().GetResult()
        if ($stdErr) { Write-Warning "Chocolatey-Suche meldet Fehler: $stdErr" }

        # Standardausgabe und Fehlerausgabe des Prozesses lesen
        $stdOut     = $stdOutTask.GetAwaiter().GetResult()
        $lines      = @($stdOut -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) # Leere Zeilen entfernen
        $results    = foreach ($line in $lines) {
            if ($line -match '^([^|]+)\|(.+)$') {
                $id      = $matches[1].Trim()
                $version = $matches[2].Trim()

                # Erst schnelle Basisergebnisse liefern; Detailanreicherung passiert asynchron in Start-Search.
                [PSCustomObject]@{
                    Id          = $id
                    Name        = $id
                    Version     = $version
                    Title       = ""
                    DisplayName = if ($version) { "$id v$version" } else { $id }
                    Raw         = $line
                }
            }
        }
        if ($results) {
            Write-Information "Gefundene Pakete:"
            $results | ForEach-Object { Write-Information $_ }
            return $results
        } else {
            Write-Information "Keine Pakete gefunden, die '$Query' entsprechen."
            return @()
        }
    } catch {
        Write-Warning "Fehler bei der Suche nach Paketen mit Query '$Query': $_"
        return @()
    }
}
function Install-Application {
    param( [string]$Name )
    Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name) | Params: `$Name=$Name"
    
    # Überprüfen, ob Chocolatey installiert ist, bevor die Installation versucht wird, um Fehler zu vermeiden
    Write-Debug "[CHECK] $($MyInvocation.MyCommand.Name) | Überprüfe Chocolatey-Installation vor Installation von '$Name'"
    if (-not $Cache.IsInstalled) { Write-Warning "Chocolatey ist nicht installiert. Installation von '$Name' ist nicht möglich."; return $false }

    # Installation des Pakets mit Chocolatey durchführen und den Erfolg oder Fehler protokollieren, um den Benutzer über den Status der Installation zu informieren
    try {
        Write-Information "Installiere Chocolatey-Paket: $Name"
        Write-Debug "[INFO] Führe Befehl aus: choco install $Name -y"
        choco install $Name -y
        Write-Information "Paket '$Name' wurde erfolgreich installiert."
        Write-Debug "[EXIT] $($MyInvocation.MyCommand.Name) | Installation von '$Name' erfolgreich."
        return $true
    } catch {
        Write-Warning "Fehler beim Installieren des Pakets '$Name': $_"
        Write-Debug "[EXIT] $($MyInvocation.MyCommand.Name) | Installation von '$Name' fehlgeschlagen."
        return $false
    }
}
function Uninstall-Application {
    param( [string]$Name )
    Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name) | Params: `$Name=$Name"

    # Überprüfen, ob Chocolatey installiert ist, bevor die Deinstallation versucht wird, um Fehler zu vermeiden
    Write-Debug "[CHECK] $($MyInvocation.MyCommand.Name) | Überprüfe Chocolatey-Installation vor Deinstallation von '$Name'"
    if (-not $Cache.IsInstalled) { Write-Warning "Chocolatey ist nicht installiert. Deinstallation von '$Name' ist nicht möglich."; return $false }

    # Deinstallation des Pakets mit Chocolatey durchführen und den Erfolg oder Fehler protokollieren, um den Benutzer über den Status der Deinstallation zu informieren
    try {
        Write-Information "Deinstalliere Chocolatey-Paket: $Name"
        Write-Debug "[INFO] Führe Befehl aus: choco uninstall $Name -y"
        choco uninstall $Name -y
        Write-Information "Paket '$Name' wurde erfolgreich deinstalliert."
        Write-Debug "[EXIT] $($MyInvocation.MyCommand.Name) | Deinstallation von '$Name' erfolgreich."
        return $true
    } catch {
        Write-Warning "Fehler beim Deinstallieren des Pakets '$Name': $_"
        Write-Debug "[EXIT] $($MyInvocation.MyCommand.Name) | Deinstallation von '$Name' fehlgeschlagen."
        return $false
    }
}
function Update-Application {
    param( [string]$Name, [string]$Manager )
    
    switch ($Manager) {
        "Choco"      { $Manager = "Chocolatey" }
        "Chocolatey" { 
            Write-Information "Aktualisiere Chocolatey-Paket: $Name"
            try {
                choco upgrade $Name -y
                Write-Information "Paket '$Name' wurde erfolgreich aktualisiert."
            } catch {
                Write-Warning "Fehler beim Aktualisieren des Pakets '$Name': $_"
            }
        }
        default { 
            Write-Warning "Unbekannter Paketmanager: $Manager. Bitte geben Sie einen gültigen Paketmanager an (z.B. 'Chocolatey')."
        }
    }
}

<# PACKAGE FUNCTIONS #>
function Get-PackageInfo {
    param ( [string]$Name, [string]$FallbackVersion = "" )

    # Überprüfen, ob Chocolatey installiert ist, bevor versucht wird, Paketinformationen abzurufen, um Fehler zu vermeiden
    Write-Debug "[CHECK] $($MyInvocation.MyCommand.Name) | Überprüfe Chocolatey-Installation vor Abrufen der Paketinformationen"
    if (-not $Cache.IsInstalled) { 
        if (Test-Installation) {
            Write-Debug "[UPDATE] $($MyInvocation.MyCommand.Name) | Aktualisiere Cache: Chocolatey-Installation bestätigt"
            $Cache.IsInstalled = $true
            Write-Information "Chocolatey-Installation bestätigt. Abrufen der Paketinformationen ist möglich."
        } else {
            Write-Debug "[EXIT] $($MyInvocation.MyCommand.Name) | Chocolatey-Installation nicht bestätigt. Abrufen der Paketinformationen abgebrochen."
            Write-Warning "Chocolatey ist nicht installiert. Abrufen der Paketinformationen ist nicht möglich."
            return
        }
    }

    Write-Debug "[INFO] Starte Prozess zum Abrufen der Paketinformationen für '$Name'"
    $process = Start-ShellProcess (Get-Command choco -ErrorAction Stop).Source "info `"$Name`""
    $stdOutTask = $process.StandardOutput.ReadToEndAsync()
    $stdErrTask = $process.StandardError.ReadToEndAsync()

    $startTime = [System.DateTime]::UtcNow
    while (-not $process.HasExited) {
        Start-Sleep -Milliseconds 60
        if ("System.Windows.Forms.Application" -as [type]) { [Application]::DoEvents() }

        $currentTime    = [System.DateTime]::UtcNow
        $elapsedSeconds = [int]($currentTime - $startTime).TotalSeconds
        if ($elapsedSeconds -ge 15) {
            Stop-ShellProcess -Process $process
            Write-Warning "Zeitüberschreitung beim Abrufen der Paketinformationen für '$Name'."
            return # $null
        }
    }

    $stdErr = $stdErrTask.GetAwaiter().GetResult()
    $stdOut = $stdOutTask.GetAwaiter().GetResult()
    if (Test-Fill $stdErr) { Write-Warning "Fehler beim Abrufen der Paketinformationen für '$Name': $stdErr" }
    $details = ConvertFrom-ChocolateyInfoText -Text $stdOut -Name $Name -FallbackVersion $FallbackVersion
    if ($details) {
        $details.DisplayName = Get-DisplayName -Package $details
        $Cache.PackageDetails[$Name] = $details
        return $details
    } else {
        Write-Warning "Konnte keine gültigen Paketinformationen für '$Name' abrufen."
        return # $null
    }

}
function Set-PackageInfo {
    param ( [System.Windows.Forms.Control]$Control, $Package, [string]$InfoLabel = "Lade Details..." )
    if (-not (Test-Control $Control)) { Write-Warning "Kein gültiges Steuerelement übergeben. Aktualisierung der Paketinformationen wird abgebrochen."; return }

    $packageInfo = if ($Control.Name -eq "PackageInfo") { $Control } else { Get-Control $Control "PackageInfo" }
    if (-not $packageInfo) { Write-Warning "Steuerelement 'PackageInfo' nicht gefunden. Aktualisierung der Paketinformationen wird abgebrochen."; return }


    # Hilfsfunktionen zur Aktualisierung der Anzeigeelemente im Paketinformationsbereich
    # - Wird ein boolescher Wert übergeben, steuert dieser die Sichtbarkeit des jeweiligen Anzeigeelements
    # - Wird ein String übergeben, wird dieser als Text gesetzt
    function Set-Info {
        param( $var, $elementName )
        $element = $packageInfo.Controls[$elementName]
        if ($null -eq $element) { Write-Warning "Anzeigeelement '$elementName' nicht gefunden. Aktualisierung dieses Elements wird übersprungen."; return }

        $element.Visible = if ($var -is [bool])   { $var } else { $true }
        $element.Text    = if ($var -is [string]) { $var } else { "" }
    }


    function Set-Label {
        param ( $var, $textAlign = "MiddleLeft", $dock = "Top" )
        $label = $packageInfo.Controls["PackageInfoLabel"]
        $label.Visible   = if ($var -is [bool])   { $var } else { $true }
        $label.Text      = if ($var -is [string]) { $var } else { "" }
        $label.TextAlign = $textAlign
        $label.Dock      = $dock
    }

    Set-Info $false "PackageInfoTitle"
    Set-Label $InfoLabel -TextAlign "MiddleCenter" -Dock "Fill"
    Set-Info $false "PackageInfoDescription"
    if (Test-Empty $Package) { return }

    $Details = Get-PackageInfo -Name $Package.Name -FallbackVersion $Package.Version
    if ($Details) {
        $infoTitle       = if ($Details.Title) { $Details.Title } else { Get-DisplayName $Details }
        $infoLabel       = "Id: $($Details.Id)`nVersion: $($Details.Version)" 
        $infoDescription = $Details.Description
        
        if ($Package.DisplayName -ne $Details.DisplayName) { Update-ListBox $Control $Details }
        if ($Details.Published) { $infoLabel += "`nVeröffentlicht: $($Details.Published)" }
        
    } else {
        $infoTitle = if ($Package.DisplayName) { $Package.DisplayName } else { $Package.Id }
        $infoLabel = "Id: $($Package.Id)`nVersion: $($Package.Version)"
        $infoDescription = "Details konnten nicht geladen werden."
    }
    Set-Info $infoTitle "PackageInfoTitle"
    Set-Label $infoLabel -TextAlign "MiddleLeft" -Dock "Top"
    Set-Info $infoDescription "PackageInfoDescription"
}
function Sync-PackageInfo {
    param( $Control, $List )

    if (Test-Empty $Control) { Write-Warning "Kein gültiges Steuerelement übergeben. Synchronisierung der Paketinformationen wird abgebrochen."; return }
    if (Test-Empty $List) { Write-Warning "Kein gültiges Listensteuerelement übergeben. Synchronisierung der Paketinformationen wird abgebrochen."; return }

    $listType = $List.GetType().Name
    $selectedItemsCount = if ($listType -eq "CheckedListBox") { $List.CheckedItems.Count } elseif ($listType -eq "ListBox") { $List.SelectedItems.Count } else { 0 }
    
    if ($selectedItemsCount -eq 0) { Set-PackageInfo -Control $Control -InfoLabel "Wähle ein Paket aus, um Details anzuzeigen." }
    elseif ($selectedItemsCount -eq 1) { Set-PackageInfo -Control $Control -Package $List.SelectedItems[0] }
    elseif ($selectedItemsCount -gt 1) { Set-PackageInfo -Control $Control -InfoLabel "Mehrere Pakete ausgewählt. Bitte wähle nur ein Paket aus, um Details anzuzeigen." }
}



<# Utility Functions #>
function Get-DisplayName {
    param( $Package )
    Write-Debug "[ENTER] $($MyInvocation.MyCommand.Name) | Params: `$Package=$Package"

    # Überprüfen, ob das Paketobjekt gültig ist, bevor versucht wird, den Anzeigenamen zu generieren, um Fehler zu vermeiden
    if (-not $Package) { return "" }

    $nameText       = switch ($true) {
                         ($Package.Title) { $Package.Title; break }
                         ($Package.Name)  { $Package.Name; break }
                         ($Package.Id)    { $Package.Id; break }
                         default { "" }
                     }
    $versionText    = if ($Package.Version) { " v$($Package.Version)" } else { "" }

    return "$nameText$versionText"
}
function ConvertFrom-ChocolateyInfoText {
    param( [string]$Text, [string]$Name, [string]$FallbackVersion = "" )

    # Initialisieren eines geordneten Hashtables mit Standardwerten für die Paketdetails, um eine konsistente Struktur zu gewährleisten
    $Details = [ordered]@{
        Id           = $Name
        Name         = $Name
        Version      = $FallbackVersion
        Title        = ""
        Published    = ""
        Authors      = ""
        Tags         = ""
        Summary      = ""
        Description  = ""
        SoftwareSite = ""
        DisplayName  = if ($FallbackVersion) { "$Name v$FallbackVersion" } else { $Name }
    }

    $descriptionLines = @()
    $inDescription = $false

    foreach ($line in ($Text -split "`r?`n")) {
        $trimmed = $line.Trim()
        $isPackagesFoundFooter = $trimmed -match '^\d+\s+packages?\s+found\.?$'

        if ($inDescription) {
            if ($line -match '^\s*[A-Za-z][A-Za-z\s-]+:\s*') { $inDescription = $false } 
            elseif ($isPackagesFoundFooter) { continue }
            elseif (Test-Fill $trimmed) { $descriptionLines += $trimmed; continue } 
            else { continue }
        }

        # Leere Zeilen überspringen; befüllte Zeilen enthalten die eigentlichen Metadaten.
        if (Test-Empty $trimmed) { continue }

        if ($trimmed -match '^([^\s]+)\s+([^\s]+)\s+\[.*\]$' -and (Test-Empty $details.Version)) {
            $details.Id = $matches[1].Trim()
            $details.Name = $details.Id
            $details.Version = $matches[2].Trim()
            continue
        }

        if ($trimmed -match '^Title:\s*([^|]+?)(?:\s*\|\s*Published:\s*(.+))?$') {
            $details.Title = $matches[1].Trim()
            if ($matches[2]) {
                $details.Published = $matches[2].Trim()
            }
            continue
        }
        if ($trimmed -match '^Tags:\s*(.+)$') { $details.Tags = $matches[1].Trim(); continue }
        if ($trimmed -match '^Authors:\s*(.+)$') { $details.Authors = $matches[1].Trim(); continue }
        if ($trimmed -match '^Summary:\s*(.+)$') { $details.Summary = $matches[1].Trim(); continue }
        if ($trimmed -match '^Description:\s*(.*)$') {
            if (-not [string]::IsNullOrWhiteSpace($matches[1])) {
                $descriptionLines += $matches[1].Trim()
            }
            $inDescription = $true
            continue
        }
        if ($trimmed -match '^Software Site:\s*(.+)$') { $details.SoftwareSite = $matches[1].Trim(); continue }
    }

    if ($descriptionLines.Count -gt 0) {
        $details.Description = ($descriptionLines -join "`n")
    }

    $details.DisplayName = Get-DisplayName -Package $details
    return [PSCustomObject]$details
}





<### EXPORT ######################################>
function Start-ChocolateyUI {
    Start-Form $FormConfig
}