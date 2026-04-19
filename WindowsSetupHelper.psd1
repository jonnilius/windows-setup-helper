@{
    RootModule        = 'WindowsSetupHelper.psm1'
    ModuleVersion     = '0.11.0'
    GUID              = '12345678-90ab-cdef-1234-567890abcdef'
    Author            = 'jonnilius'
    CompanyName       = 'BORINAS'
    Copyright         = '(c) 2026 jonnilius'
    Description       = 'Windows Setup Helper'
    PowerShellVersion = '5.1'

    NestedModules     = @(
        'FormBuilder.psd1'
        'Utils.psm1'
    )
}