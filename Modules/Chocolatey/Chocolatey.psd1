@{
    RootModule      = 'Chocolatey.psm1'
    ModuleVersion   = '1.0.0'
    GUID            = 'fff42963-2efc-4c0a-9763-de1bded8e568'
    Author          = 'jonnilius'
    Description     = 'Chocolatey Management Module for Windows Setup Helper'

    RequiredModules = @('FormBuilder', 'Utils')

    FunctionsToExport   = @('Start-ChocolateyUI')
    CmdletsToExport     = @()
    VariablesToExport   = @()
    AliasesToExport     = @()
}