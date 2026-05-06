@{
    RootModule        = 'PowerStatus.psm1'
    ModuleVersion     = '1.1.0'
    GUID              = 'fb8f1ef5-1d95-4008-8ad0-a2e813f749e1'
    Author            = 'jonnilius'
    Description       = 'Power Status Management Module for Windows Setup Helper'

    RequiredModules     = @( 'FormBuilder', 'Utils' )

    FunctionsToExport   = @('Show-PowerForm', 'Update-PowerTab', 'Update-PowerStatus', 'Initialize-PowerTab', 'Get-PowerStatus', 'Set-PowerStatus')
    CmdletsToExport     = @()
    VariablesToExport   = @()
    AliasesToExport     = @()
}