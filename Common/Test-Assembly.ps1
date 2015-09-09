#Inspired on: https://msdn.microsoft.com/en-us/library/ms173100.aspx
Function Test-Assembly {
<#
    .Synopsis
        Test is file is .Net Assembly
    .DESCRIPTION
        check if file is usable as assembly in powershell.
    .NOTES
        Author:	Proxx
        Web:	www.Proxx.nl 
        Date:	25-08-2015
    .LINK
        http://www.Proxx.nl
#>
    Param(
    
    
    [Parameter(ValueFromPipeline=$true)]
    [String[]]$Path)

    Begin {}

    Process {
        ForEach($File in $Path) {
            try
            {
                [System.Reflection.AssemblyName] $testAssembly = [System.Reflection.AssemblyName]::GetAssemblyName($File)
                Write-Output ([PSCustomObject] @{
                    Name = $testAssembly.Name
                    Version = $testAssembly.Version
                    Dll = $File
                    Assembly = $true
                    Error = $null
                })
            }
            catch [System.IO.FileNotFoundException]
            {
                Write-Output ([PSCustomObject] @{
                    Name = $testAssembly.Name
                    Version = $testAssembly.Version
                    Dll = $File
                    Assembly = $false
                    Error = "The file cannot be found."
                })
            }

            catch [System.BadImageFormatException]
            {
                Write-Output ([PSCustomObject] @{
                    Name = $testAssembly.Name
                    Version = $testAssembly.Version
                    Dll = $File
                    Assembly = $false
                    Error = "The file is not an assembly."
                })
            }

            catch [System.IO.FileLoadException]
            {
                Write-Output ([PSCustomObject] @{
                    Name = $testAssembly.Name
                    Version = $testAssembly.Version
                    Dll = $File
                    Assembly = $false
                    Error = "The assembly has already been loaded."
                })
            }
        }
    }
    End { }
}