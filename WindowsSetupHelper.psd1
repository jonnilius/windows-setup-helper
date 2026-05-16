@{
    RootModule        = 'WindowsSetupHelper.psm1'
    ModuleVersion     = '0.11.3'
    GUID              = '12345678-90ab-cdef-1234-567890abcdef'
    Author            = 'jonnilius'
    CompanyName       = 'BORINAS'
    Copyright         = '(c) 2026 jonnilius'
    Description       = 'Tools zum Einrichten und Konfigurieren eines Windows-Systems'
    PowerShellVersion = '5.1'

    NestedModules     = @( 'FormBuilder.psd1', 'Utils.psm1' )
}