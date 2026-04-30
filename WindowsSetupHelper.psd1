@{
    RootModule        = 'WindowsSetupHelper.psm1'
    ModuleVersion     = '0.11.1'
    GUID              = '12345678-90ab-cdef-1234-567890abcdef'
    Author            = 'jonnilius'
    CompanyName       = 'BORINAS'
    Copyright         = '(c) 2026 jonnilius'
    Description       = 'Tool zum Einrichten eines Windows-Systems'
    PowerShellVersion = '5.1'

    NestedModules     = @(
        'FormBuilder.psd1'
        'Utils.psm1'
    )
}