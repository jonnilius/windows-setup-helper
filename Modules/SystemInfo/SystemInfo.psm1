
# Funktionen zum Abrufen von Windows- und Geräteinformationen
function Get-WindowsInfo {
    param (
        [switch]$Edition,
        [switch]$Version,
        [switch]$Build,
        [switch]$Key
    )
    
    # Gebe die angeforderten Informationen zurück
    switch ($true) {
        $Edition { return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName }
        $Version { return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion }
        $Build   { 
            # $currentBuild = [System.Environment]::OSVersion.Version.Build
            $currentVersion = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
            return $currentVersion.CurrentBuild + "." + $currentVersion.UBR }
        $Key     { 
            $SoftwareProtectionPlatform = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
            return $SoftwareProtectionPlatform.BackupProductKeyDefault
        }
    }
}
function Get-DeviceInfo {
    param (
        [switch]$Name,
        [switch]$Processor,
        [switch]$RAM,
        [switch]$GPU,
        [switch]$Storage,
        [switch]$ID,
        [switch]$ProductID,
        [switch]$SystemType
    )
    # Gebe die angeforderten Informationen zurück
    switch ($true) {
        $Name       { 
            # [System.Environment]::MachineName
            return (Get-CimInstance Win32_ComputerSystem).Name 
        }
        $Processor  { 
            # [System.Environment]::ProcessorCount # Anzahl der logischen Prozessoren
            return (Get-CimInstance Win32_Processor).Name 
        }
        $RAM        { 
            $totalRAM   = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2) 
            $avaibleRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
            return "$totalRAM GB ($avaibleRAM GB verwendbar)"
        }
        $GPU        { return (Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name) -join ", " }
        $Storage    { 
            $disk = Get-CimInstance Win32_DiskDrive | Select-Object -First 1
            $sizeGB = [math]::Round($disk.Size / 1GB, 0)
            $diskModel = $disk.Model.Trim()
            $diskType = (Get-PhysicalDisk | Where-Object { $_.Model -eq $diskModel }).MediaType
            return "$sizeGB GB $diskType $diskModel"
        }
        $ID         { return (Get-CimInstance Win32_ComputerSystem).Name }
        $ProductID  { return (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductId }
        $SystemType { 
            # [System.Environment]::Is64BitOperatingSystem
            return (Get-CimInstance Win32_ComputerSystem).SystemType 
        }
    }
}
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
        [switch]$SystemType
    )

    # Gebe die angeforderten Informationen zurück
    switch ($true) {
        $WindowsEdition   { return Get-WindowsInfo -Edition }
        $WindowsVersion   { return Get-WindowsInfo -Version }
        $WindowsBuild     { return Get-WindowsInfo -Build }
        $WindowsKey       { return Get-WindowsInfo -Key }
        $DeviceName       { return Get-DeviceInfo -Name }
        $DeviceProcessor  { return Get-DeviceInfo -Processor }
        $DeviceRAM        { return Get-DeviceInfo -RAM }
        $DeviceGPU        { return Get-DeviceInfo -GPU }
        $DeviceStorage    { return Get-DeviceInfo -Storage }
        $DeviceID         { return Get-DeviceInfo -ID }
        $ProductID        { return Get-DeviceInfo -ProductID }
        $SystemType       { return Get-DeviceInfo -SystemType }
    }
}

# 
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

    # Aktualisiere den Label-Text, um die Änderungen anzuzeigen
    $Label.Refresh()
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