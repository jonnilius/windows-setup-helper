@{
    RootModule        = "FormBuilder.psm1"
    ModuleVersion     = "1.0.0"
    GUID              = "ebe0799e-734e-451d-9bb1-34983dd82f05"
    Author            = "jonnilius"
    Description       = "Form Erstellungs-Modul für Windows Setup Helper"

    RequiredModules   = @( 'Utils' )
    NestedModules     = @( 'SubModules/SubModules.psd1' )
}