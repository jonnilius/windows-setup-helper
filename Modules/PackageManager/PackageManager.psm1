
function Get-InstalledPrograms {
    if ($script:InstalledProgramsCache) {
        return $script:InstalledProgramsCache
    }

    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $registryApps = foreach ($path in $registryPaths) {
        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {
            -not [string]::IsNullOrWhiteSpace($_.DisplayName)
        } | ForEach-Object {
            [PSCustomObject]@{
                Id                   = if ($_.PSChildName) { $_.PSChildName } else { $_.DisplayName }
                Name                 = $_.DisplayName.Trim()
                Version              = [string]$_.DisplayVersion
                Source               = "Registry"
                WingetId             = $null
                UninstallString      = [string]$_.UninstallString
                QuietUninstallString = [string]$_.QuietUninstallString
            }
        }
    }

    $registryApps = $registryApps |
        Group-Object Name, Version |
        ForEach-Object { $_.Group | Select-Object -First 1 }

    $appsByName = @{}
    foreach ($app in $registryApps) {
        if ([string]::IsNullOrWhiteSpace($app.Name)) { continue }
        $appsByName[$app.Name.ToLowerInvariant()] = $app
    }

    $canReadWingetPackages = (Get-Command -Name "winget.exe" -ErrorAction SilentlyContinue) -and
                             (Get-Command -Name "Get-WinGetPackage" -ErrorAction SilentlyContinue)

    if ($canReadWingetPackages) {
        try {
            foreach ($wingetApp in @(Get-WinGet -List)) {
                if ([string]::IsNullOrWhiteSpace($wingetApp.Name)) { continue }

                $key = $wingetApp.Name.ToLowerInvariant()
                if ($appsByName.ContainsKey($key)) {
                    $appsByName[$key].WingetId = $wingetApp.Id
                    $appsByName[$key].Source = "Registry, WinGet"
                    if ([string]::IsNullOrWhiteSpace($appsByName[$key].Version) -and $wingetApp.PSObject.Properties["Version"]) {
                        $appsByName[$key].Version = [string]$wingetApp.Version
                    }
                } else {
                    $appsByName[$key] = [PSCustomObject]@{
                        Id                   = $wingetApp.Id
                        Name                 = $wingetApp.Name
                        Version              = if ($wingetApp.PSObject.Properties["Version"]) { [string]$wingetApp.Version } else { "" }
                        Source               = "WinGet"
                        WingetId             = $wingetApp.Id
                        UninstallString      = $null
                        QuietUninstallString = $null
                    }
                }
            }
        } catch {
            Write-Warning "WinGet-Pakete konnten nicht gelesen werden: $($_.Exception.Message)"
        }
    }

    $script:InstalledProgramsCache = @($appsByName.Values | Sort-Object Name)
    return $script:InstalledProgramsCache
}

function Update-InstalledProgramsList {
    param( [System.Windows.Forms.ListView]$ListView )
    
    $ListView.BeginUpdate()
    try {
        $ListView.Items.Clear()
        $InstalledPrograms = Get-InstalledPrograms
        foreach ($program in $InstalledPrograms) { 
            $item = New-ListViewItem $program.Name @(
                [string]$program.Version,
                [string]$program.Source,
                [string]$(if ($program.WingetId) { $program.WingetId } else { $program.Id })
            )
            $item.Tag = $program
            [void]$ListView.Items.Add($item)
        }
        foreach ($column in $ListView.Columns) { $column.Width = -2 }
    } finally {
        $ListView.EndUpdate()
    }
}

function Invoke-InstalledProgramUninstall {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IEnumerable]$Programs
    )

    $selectedPrograms = @($Programs)
    if ($selectedPrograms.Count -eq 0) { return }
    if (-not (Show-MessageBox "UninstallPackagesConfirm")) { return }

    Show-ProgressDialog -Text "Deinstallation wird vorbereitet..." | Out-Null

    try {
        foreach ($program in $selectedPrograms) {
            Update-ProgressDialog -Text "Deinstalliere $($program.Name)..."

            if ($program.WingetId) {
                Get-WinGet -ShowText {
                    param($msg, [switch]$Final)
                    Update-ProgressDialog -Text $msg
                } -UninstallApps @([PSCustomObject]@{
                    Id   = $program.WingetId
                    Name = $program.Name
                })
                continue
            }

            $command = if (-not [string]::IsNullOrWhiteSpace($program.QuietUninstallString)) {
                $program.QuietUninstallString
            } else {
                $program.UninstallString
            }

            if ([string]::IsNullOrWhiteSpace($command)) {
                Update-ProgressDialog -Text "Keine Deinstallationsroutine für $($program.Name) gefunden."
                Start-Sleep -Seconds 1
                continue
            }

            Start-Command $command | Out-Null
        }

        $script:InstalledProgramsCache = $null
        Close-ProgressDialog -Text "Deinstallation abgeschlossen." -DelaySeconds 1
    } catch {
        Close-ProgressDialog -Text "Deinstallation fehlgeschlagen." -SubText $_.Exception.Message -DelaySeconds 2
        throw
    }
}