
function Get-PowerStatus {
    param ( 
        [ValidateSet("AC", "DC")]
        [string]$PowerScheme = "AC", 
        [string]$StatusType = "Standby", 
        [switch]$ReturnSeconds,
        [switch]$TextOutput
        )

    $result = switch ($StatusType) {
        "Standby"   { powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE }
        "Hibernate" { powercfg /query SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE }
        "Monitor"   { powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE }
        default     { throw "Ungültiger StatusType. Verwenden Sie 'Standby', 'Hibernate' oder 'Monitor'." }
    }
    $powerString    = if ($PowerScheme -eq "AC") { "Wechselstrom" } elseif ($PowerScheme -eq "DC") { "Gleichstrom" }
    $value          = ($result | Select-String $powerString).ToString().Split(":")[-1].Trim()
    $seconds        = [convert]::ToInt32($value, 16)
    $minutes        = $seconds / 60

    # Rückgabe basierend auf den Parametern
    if ($TextOutput -and $seconds -eq 0) { return "Nie" }
    elseif ($TextOutput -and $ReturnSeconds) { return "$seconds Sekunden" } 
    elseif ($TextOutput) { return "$minutes Minuten" } 
    elseif ($ReturnSeconds) { return $seconds } 
    else { return $minutes }
}
function Set-PowerStatus {
    param ( [ValidateSet("AC", "DC")][string]$PowerScheme = "AC", [string]$StatusType = "Standby", [int]$Minutes )

    if ($Minutes -lt 0) { throw "Ungültige Minutenanzahl. Bitte geben Sie eine positive Zahl ein." }

    switch ($StatusType) {
        "Standby"   { if ($PowerScheme -eq "AC") { powercfg /change standby-timeout-ac $Minutes } elseif ($PowerScheme -eq "DC") { powercfg /change standby-timeout-dc $Minutes }}
        "Hibernate" { if ($PowerScheme -eq "AC") { powercfg /change hibernate-timeout-ac $Minutes } elseif ($PowerScheme -eq "DC") { powercfg /change hibernate-timeout-dc $Minutes }}
        "Monitor"   { if ($PowerScheme -eq "AC") { powercfg /change monitor-timeout-ac $Minutes } elseif ($PowerScheme -eq "DC") { powercfg /change monitor-timeout-dc $Minutes }}
        default     { throw "Ungültiger StatusType. Verwenden Sie 'Standby', 'Hibernate' oder 'Monitor'." }
    }
}
function Update-PowerStatus {
    param ( [ValidateSet("AC", "DC")][string]$PowerScheme = "AC", [string]$StatusType = "Standby" )

    $CurrentMinutes = Get-PowerStatus -PowerScheme $PowerScheme -StatusType $StatusType
    $GroupBoxText   = if ($StatusType -eq "Standby") { "Energiesparmodus " } elseif ($StatusType -eq "Hibernate") { "Ruhezustand " } elseif ($StatusType -eq "Monitor") { "Bildschirm ausschalten " }
    $GroupBoxText  += if ($PowerScheme -eq "AC") { "(Netzbetrieb)" } elseif ($PowerScheme -eq "DC") { "(Akkubetrieb)" }

    Show-PowerStatusForm -GroupBoxText $GroupBoxText -CurrentMinutes $CurrentMinutes -StatusType $StatusType -PowerScheme $PowerScheme
}

<# POWERTAB #>
function Update-PowerTab {
    param ( $control )

    $PowerValues = @{
        "StandbyValueAC"    = Get-PowerStatus "AC" "Standby" -TextOutput
        "HibernateValueAC"  = Get-PowerStatus "AC" "Hibernate" -TextOutput
        "MonitorValueAC"    = Get-PowerStatus "AC" "Monitor" -TextOutput
        "StandbyValueDC"    = Get-PowerStatus "DC" "Standby" -TextOutput
        "HibernateValueDC"  = Get-PowerStatus "DC" "Hibernate" -TextOutput
        "MonitorValueDC"    = Get-PowerStatus "DC" "Monitor" -TextOutput
    }
    foreach ($Values in $PowerValues.GetEnumerator()) {
        $label      = Get-Control $control $Values.Key
        $label.Text = $Values.Value
        if ($label.Text -ne "Nie") { (Get-Control $control "DisableSleep").Visible = $true }

        $label.Add_TextChanged({ (Get-Control $this "DisableSleep").Visible = $this.Text -ne "Nie" })
    }
}