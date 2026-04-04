# Windows Setup Helper

Ein PowerShell-basiertes GUI-Tool zur Einrichtung und Verwaltung von Windows-Systemen.

## Features

- **System** – Systeminformationen anzeigen und Gerätename bearbeiten
- **Debloat** – OneDrive, Microsoft Edge und Start-Menü-Icons entfernen
- **Paketverwaltung** – Anwendungen über Chocolatey und WinGet suchen, installieren, aktualisieren und deinstallieren
- **Energieoptionen** – Energiesparpläne für Netzbetrieb und Akkubetrieb konfigurieren

## Voraussetzungen

- Windows 10 / 11
- PowerShell 5.1 oder neuer
- Administratorrechte
- [Chocolatey](https://chocolatey.org/) *(optional, für Paketverwaltung)*
- [WinGet](https://aka.ms/winget) *(optional, für Paketverwaltung)*

## Verwendung

1. `WindowsSetupHelper.ps1` als Administrator ausführen.
2. Das Skript fordert bei Bedarf automatisch erhöhte Rechte an.
3. Im Hauptfenster die gewünschte Registerkarte auswählen und die gewünschten Aktionen durchführen.

## Projektstruktur

```
windows-setup-helper/
├── Assets/Icons/          # Anwendungs- und Steuerelemente-Icons
├── Debloat/               # Eigenständige Debloat-Skripte
├── Modules/
│   ├── Chocolatey/        # Chocolatey-Integration
│   ├── PacketManager/     # WinGet-Integration
│   ├── FormBuilder.psm1   # GUI-Framework
│   └── Utils.psm1         # Hilfsfunktionen
├── packages.config        # Vordefinierte Chocolatey-Pakete
└── WindowsSetupHelper.ps1 # Hauptanwendung
```

## Lizenz

MIT – siehe [LICENSE](LICENSE)
