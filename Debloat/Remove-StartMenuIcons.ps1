using namespace System.Windows.Forms
param ( $take )
Add-Type -AssemblyName System.Windows.Forms


# Administratorrechte überprüfen
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    [System.Environment]::Exit(0)
}

# Statusaktualisierungsfunktion
$ShowText = {
    <#
    .SYNOPSIS
        Zeigt eine Statusmeldung an.
    .PARAMETER msg
        Die anzuzeigende Nachricht.
    .PARAMETER Final
        Gibt an, ob dies die letzte Nachricht ist.
    #>
    param($msg, [switch]$Final)

    # Überprüfen, ob die Funktion Update-Status verfügbar ist
    if (Get-Command Update-Status -ErrorAction SilentlyContinue) {
        Update-Status -Label (Get-ProcessLabel $take "Main") -Message $msg -Delay 1 -Final:$Final
    } else {
        # Fallback: Nachricht in der Konsole ausgeben
        Write-Host $msg
        if ($Final) {
            Write-Host "Fertig!" -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
    }
}

# Bestätigungsdialog anzeigen, bevor die Startmenü-Icons entfernt werden
$Request = {
    $Title   = "Bestätigung"
    $Text    = "Möchtest du wirklich alle Startmenü-Icons entfernen?"
    $Buttons = [MessageBoxButtons]::YesNo
    $Icon    = [MessageBoxIcon]::Warning 
    $YesNo   = [System.Windows.Forms.DialogResult]::Yes

    # Zeige den Bestätigungsdialog an
    $confirm = [MessageBox]::Show($Text, $Title, $Buttons, $Icon)

    # Überprüfe die Benutzerantwort und gib true zurück, wenn "Yes" ausgewählt wurde, andernfalls false
    return  $confirm -eq $YesNo
}
if (-not (& $Request)) {
    & $ShowText "Entfernung der Startmenü-Icons abgebrochen." -Final
    return
}

# Statusmeldung anzeigen
& $ShowText "Entferne Startmenü-Icons..."

# Definiere Startmenü-Layout als XML-String
& $ShowText "Definiere ein Startmenü-Layout..."
$layoutFile = "C:\Windows\StartMenuLayout.xml"
If ( Test-Path $layoutFile ) { Remove-Item $layoutFile }
$START_MENU_LAYOUT = @"
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
<LayoutOptions StartTileGroupCellWidth="6" />
<DefaultLayoutOverride>
<StartLayoutCollection>
    <defaultlayout:StartLayout GroupCellWidth="6" />
</StartLayoutCollection>
</DefaultLayoutOverride>
</LayoutModificationTemplate>
"@
$START_MENU_LAYOUT | Out-File $layoutFile -Encoding ASCII

# Weise das Startlayout zu und erzwinge die Anwendung mit "LockedStartLayout" sowohl auf Maschinen- als auch auf Benutzerebene
& $ShowText "Startmenü-Layout zuweisen und Anwendung erzwingen..."
$regAliases = @("HKLM", "HKCU")
foreach ($regAlias in $regAliases){
    $basePath   = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
    $keyPath    = $basePath + "\Explorer" 

    if(!(Test-Path -Path $keyPath)) { New-Item -Path $basePath -Name "Explorer" }

    Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 1
    Set-ItemProperty -Path $keyPath -Name "StartLayoutFile" -Value $layoutFile
}

# Explorer neu starten, damit die Änderungen wirksam werden
& $ShowText "Starte den Explorer neu..."
Stop-Process -name explorer -Force
Start-Sleep -Seconds 3

# Öffne das Startmenü, damit die Layout-Änderungen angewendet werden, und warte kurz, um sicherzustellen, dass alles aktualisiert ist.
& $ShowText "Öffne das Startmenü, damit die Layout-Änderungen angewendet werden..."
$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^{ESCAPE}')
Start-Sleep -Seconds 3

# Entfernen der Sperre, damit Benutzer das Startmenü-Layout wieder anpassen können, falls gewünscht.
& $ShowText "Entferne die Sperre, damit Benutzer das Startmenü-Layout wieder anpassen können..."
foreach ($regAlias in $regAliases){
    $basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
    $keyPath = $basePath + "\Explorer" 
    Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 0
}

# Explorer neu starten und die Layout-Datei löschen
& $ShowText "Starte den Explorer neu und lösche die Layout-Datei..."
Stop-Process -name explorer -Force
Import-StartLayout -LayoutPath $layoutFile -MountPath $env:SystemDrive\
Remove-Item $layoutFile -Force
    
& $ShowText "Startmenü-Icons wurden erfolgreich entfernt!" -Final


    


