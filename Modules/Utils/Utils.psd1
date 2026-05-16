@{
    RootModule        = 'Utils'
    ModuleVersion     = '1.0.0'
    GUID              = '7555e9af-36c6-4a18-88cb-819d18ffc2f8'
    Author            = 'jonnilius'
    Description       = 'Interne Unter-Module für FormBuilder'

    NestedModules     = @(
        'Cache.psm1'
        'PSConsole.psm1'
        'Window.psm1'
    )

    FunctionsToExport = @('*')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}