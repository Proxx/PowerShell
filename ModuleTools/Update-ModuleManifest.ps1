Function Update-ModuleManifest {
<#
    .Synopsis
        Updates Modulemanifest file.
    .DESCRIPTION
        Add, Change or Remove parameters from module manifest.
    .EXAMPLE
        Update-ModuleManifest -Path $PSScriptRoot\Module.psd1 -OutputPath $PSScriptRoot\NewModuleManifest.psd1 -Confirm
    .EXAMPLE
        Update-ModuleManifest -Path $PSScriptRoot\Module.psd1 -Whatif
    .NOTES
        Author: Proxx
        Web:	www.Proxx.nl 
        Date:	26-08-2015
        
        TODO:
            - AutoGenerate $FileList based on Test-Manifest.
#>

    [cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
    Param(
        [String[]] $AliasesToExport,
        [String] $Author,
        [Version] $ClrVersion,
        [String[]] $CmdletsToExport,
        [String] $CompanyName,
        [String] $Copyright,
        [String] $Description,
        [Version] $DotNetFrameworkVersion,
        [String[]] $FileList,
        [String[]] $FormatsToProcess,
        [String[]] $FunctionsToExport,
        [Guid] $Guid,
        [String] $HelpInfoUri,
        [Object[]] $ModuleList,
        [Version] $ModuleVersion,
        [Object[]] $NestedModules,
        [Parameter(Mandatory=$true, Position=0)]
        [String] $Path,
        [String] $PowerShellHostName,
        [Version] $PowerShellHostVersion,
        [Version] $PowerShellVersion,
        [Object] $PrivateData,
        $ProcessorArchitecture,
        [String[]] $RequiredAssemblies,
        [Object[]] $RequiredModules,
        [String[]] $ScriptsToProcess,
        [String[]] $TypesToProcess,
        [String[]] $VariablesToExport,
        [String] $DefaultCommandPrefix,
        [String] $RootModule,
        [Parameter(Position=1)]
        [String] $OutputPath
    )

    $Manifest = Test-ModuleManifest -Path $Path -ErrorAction Stop

    $Params = @{}
    $Manifest.PSObject.Properties | ?{ ("Name","ExportedWorkflows", "ModuleBase", "ExportedCommands", "Tags", "ModuleType") -notcontains $_.Name } | %{ 
        if ($_.Value) { 
            [String] $Name = ""
            Switch(($_)) 
            {
                { $_.Name -eq "ExportedFunctions" }    { $Name = "FunctionsToExport"; [String[]] $Value = $_.Value.Keys }
                { $_.Name -eq "ExportedAliases" }      { $Name = "AliasesToExport"; [String[]] $Value = $_.Value.Keys }
                { $_.Name -eq "ExportedCmdlets" }      { $Name = "CmdletsToExport"; [String[]] $Value = $_.Value.Keys }
                { $_.Name -eq "ExportedDscResources" } { $Name = "DscResourcesToExport"; [String[]] $Value = $_.Value.Keys }
                { $_.Name -eq "ExportedVariables" }    { $Name = "VariablesToExport"; [String[]] $Value = $_.Value.Keys }
                { $_.Name -eq "Scripts" }              { $Name = "ScriptsToProcess"; $Value = $_.Value }
                { $_.Name -eq "Prefix" }               { $Name = "DefaultCommandPrefix"; $Value = $_.Value }
                { $_.Name -eq "Version" }              { $Name = "ModuleVersion"; $Value = $_.Value }
                default                { $Name = $_.Name; $Value = $_.Value }
            }
            $Params.Add($Name,$Value)
            Remove-Variable -Name Value -Confirm:$false -WhatIf:$false
        }
    }


    if ($Manifest.PrivateData.PSData.Tags) { $Params.Tags = $Manifest.PrivateData.PSData.Tags }
    $Params.Remove("PrivateData")


    $PSBoundParameters.GetEnumerator() | ForEach {
        Try {
            $Params.Remove($_.Key)
        } Catch { $_ }
        $Params.Add($_.Key,$_.Value) 
    }
    if ($OutputPath) { $Params.Remove("OutputPath"); $Params.Path = $OutputPath }
    New-ModuleManifest @Params
}