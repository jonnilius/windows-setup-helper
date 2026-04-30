# SystemInfo.psm1 - Funktionen zum Abrufen von Systeminformationen und Verwalten von Geräteinformationen

# Diese Funktionen ermöglichen das Abrufen von Informationen über die Windows-Edition, -Version, -Build, -Produktschlüssel
function Get-WindowsEdition { return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName }
function Get-WindowsVersion { return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion }
function Get-WindowsBuild { return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild + "." + (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").UBR }
function Get-WindowsKey { return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform").BackupProductKeyDefault }

function Get-DeviceName { return (Get-CimInstance Win32_ComputerSystem).Name }
function Get-DeviceProcessor { return (Get-CimInstance Win32_Processor).Name }
function Get-DeviceRAM { 
    $totalRAM   = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2) 
    $avaibleRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    return "$totalRAM GB ($avaibleRAM GB verwendbar)"
}
function Get-DeviceGPU { return (Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name) -join ", " }
function Get-DeviceStorage { 
    $disk = Get-CimInstance Win32_DiskDrive | Select-Object -First 1
    $sizeGB = [math]::Round($disk.Size / 1GB, 0)
    $diskModel = $disk.Model.Trim()
    $diskType = (Get-PhysicalDisk | Where-Object { $_.Model -eq $diskModel }).MediaType
    return "$sizeGB GB $diskType $diskModel"
}
function Get-DeviceID { return (Get-CimInstance Win32_ComputerSystem).Name }
function Get-ProductID { return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductId }
function Get-SystemType { return (Get-CimInstance Win32_ComputerSystem).SystemType }

function Get-SystemInfo {
    param (
        [switch]$WindowsEdition,
        [switch]$WindowsVersion,
        [switch]$WindowsBuild,
        [switch]$WindowsKey,
        [switch]$DeviceName,
        [switch]$DeviceProcessor,
        [switch]$DeviceRAM,
        [switch]$DeviceGPU,
        [switch]$DeviceStorage,
        [switch]$DeviceID,
        [switch]$ProductID,
        [switch]$SystemType,
        [string]$Property
    )
    # Wenn eine spezifische Property angefragt wird, rufe die Funktion rekursiv mit dem entsprechenden Switch auf, um nur diese Information zurückzugeben
    if ($Property) {
        $propertyNames = @(
            "WindowsEdition", "WindowsVersion", "WindowsBuild", "WindowsKey",
            "DeviceName", "DeviceProcessor", "DeviceRAM", "DeviceGPU", "DeviceStorage",
            "DeviceID", "ProductID", "SystemType"
        )
        if ($propertyNames -notcontains $Property) { throw "Ungültige Property. Erlaubte Werte: $($propertyNames -join ", ")" }
        else { $params = @{ $Property = $true }; return Get-SystemInfo @params }
    }

    # Gebe die angeforderten Informationen zurück
    switch ($true) {
        $WindowsEdition   { return Get-WindowsEdition }
        $WindowsVersion   { return Get-WindowsVersion }
        $WindowsBuild     { return Get-WindowsBuild }
        $WindowsKey       { return Get-WindowsKey }
        $DeviceName       { return Get-DeviceName }
        $DeviceProcessor  { return Get-DeviceProcessor }
        $DeviceRAM        { return Get-DeviceRAM }
        $DeviceGPU        { return Get-DeviceGPU }
        $DeviceStorage    { return Get-DeviceStorage }
        $DeviceID         { return Get-DeviceID }
        $ProductID        { return Get-ProductID }
        $SystemType       { return Get-SystemType }
    }
}

function Enable-LabelCopyOnClick {
    param ( [Parameter(Mandatory=$true)][System.Windows.Forms.Label]$Label )

    # Speichere den ursprünglichen Text im Tag-Property, damit wir ihn später wiederherstellen können
    $Label.Tag = $Label.Text

    # Cursor auf Hand ändern, um anzuzeigen, dass es klickbar ist
    $Label.Cursor = Get-Cursor "Hand"

    # Füge MouseEnter- und MouseLeave-Events hinzu, um den Text und die Schriftart zu ändern
    $Label.Add_MouseEnter({ $this.Text = "Klicken zum Kopieren";    $this.Font = Get-Font -Preset "TableTextHover" })
    $Label.Add_MouseLeave({ $this.Text = $this.Tag;                 $this.Font = Get-Font -Preset "TableText" })

    # Füge ein Click-Event hinzu, um den Text in die Zwischenablage zu kopieren
    $Label.Add_Click({
        Set-Clipboard -Value $this.Tag
        Show-MessageBox -Text "'$($this.Tag)' wurde in die Zwischenablage kopiert." -Title "Kopiert" -Buttons "OK" -Icon "Information"
    })
}

function Set-DeviceName { 
    $params = @{
        Title        = "PC umbenennen"
        Label        = "Neuer PC-Name:"
        DefaultValue = $env:COMPUTERNAME
        Icon         = "DeviceName"
        OKButtonText = "Umbenennen"
        WarningMessage = $null
    }
    while ($true) {
        $result = Show-TextInput @params
        if ($result -eq $false) { break }

        $result = $result.Trim()
        if ($result -eq "") { $params.WarningMessage = "Der PC-Name darf nicht leer sein."; continue }
        elseif ($result -eq $params.DefaultValue) { $params.WarningMessage = "Die Namen müssen sich unterscheiden."; continue }
        elseif ($result -match '[\\\/:\*\?"<>\|]') { $params.WarningMessage = "Der PC-Name darf keine der folgenden Zeichen enthalten: \ / : * ? < > |"; continue }
        else {
            try {
                Rename-Computer -NewName $result -Force -ErrorAction Stop
                $params.WarningMessage = $null
                $confirmRestart = Show-MessageBox -Text "Der PC-Name wurde erfolgreich geändert. `nMöchten Sie jetzt neu starten, damit die Änderung wirksam wird?" -Title "Neustart erforderlich" -Buttons "YesNo" -Icon "Information"
                if ($confirmRestart) { Restart-Computer -Force }
                break
            } catch {
                $params.WarningMessage = "Ungültige Eingabe."
            }
        }
    }
}