param (){
    $confirm = [System.Windows.Forms.MessageBox]::Show(
                "Möchten Sie WinGet wirklich entfernen?", 
                "Bestätigung", 
                [System.Windows.Forms.MessageBoxButtons]::YesNo, 
                [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($confirm -eq [System.Windows.Forms.DialogResult]::No) { return }
    
    Start-Sleep -Seconds 1
    Write-Host "WinGet Entferner kommt noch..."
    Start-Sleep -Seconds 1

    [System.Windows.Forms.MessageBox]::Show(
        "WinGet wurde erfolgreich entfernt.", 
        "Erfolg", 
        [System.Windows.Forms.MessageBoxButtons]::OK, 
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}