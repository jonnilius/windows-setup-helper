@{
    RootModule        = ''
    ModuleVersion     = '1.1.0'
    GUID              = 'd72163b9-4eee-44a2-9c0f-ba6b99499e91'
    Author            = 'jonnilius'
    Description       = 'Interne Unter-Module für FormBuilder'

    NestedModules     = @(
        'Color.psm1'
        'Cursor.psm1'
        'Draw.psm1'
        'Font.psm1'
        'Icon.psm1'
    )

    FunctionsToExport = @('*')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
