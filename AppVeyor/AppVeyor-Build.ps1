#build script

#Loading functions
iex ((new-object net.webclient).DownloadString('https://gist.githubusercontent.com/Proxx/d7e288dee93408949adf/raw/Update-ModuleManifest.ps1'))

#Variable
$PSModulePath = [System.Environment]::GetEnvironmentVariable("PSModulePath","User")
$ModuleName = $ENV:APPVEYOR_PROJECT_NAME
$ModulePath = Join-Path -Path  $PSModulePath -ChildPath $ModuleName
$ModuleRoot = $ENV:APPVEYOR_BUILD_FOLDER
$ModuleVersion = $ENV:APPVEYOR_BUILD_VERSION

if (-Not (Test-Path -Path $ModulePath)) { New-Item -Path $ModulePath -ItemType Directory | Out-Null }

$Param = @{
    FilePath = "$ModulePath\$ModuleName.psm1"
    Encoding = "ascii"
}
Get-ChildItem -Path "$ModuleRoot\*" -Include "*.ps1", "LICENSE", "*.dll", "*.xml" | ForEach {
    if ($_.Extension -eq '.ps1') 
    {
        Get-Content -Path $_.FullName -Raw | Out-File @Param
        $Param.Append = $true
        "`n" | Out-file @Param
    }
    else
    {
        Copy-Item -Path $_.FullName -Destination "$ModulePath\" -WhatIf # Debug line remove later
        Copy-Item -Path $_.FullName -Destination "$ModulePath\"
    }
}

Update-ModuleManifest -ModuleVersion $ModuleVersion -Path "$ModuleRoot\$ModuleName.psd1" -OutputPath "$ModulePath\$ModuleName.psd1"
Test-ModuleManifest "$ModulePath\$ModuleName.psd1"