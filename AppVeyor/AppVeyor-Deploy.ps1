Function AppVeyor-Deploy {
<#
    .Synopsis
        Automatic publish Powershell module to Repository with new version
    .DESCRIPTION
        Automatic publish Powershell module to Repository with new version
    .NOTES
        Author: Proxx
        Web:	www.Proxx.nl 
        Date:	27-08-2015
#>
    [cmdletbinding()]
    Param(
        [String] $Repository="PSGallery"
    )

    Begin {
        #Loading Module
        Import-Module -Name PowerShellGet
        #Loading functions 
        iex ((new-object net.webclient).DownloadString('https://gist.githubusercontent.com/Proxx/d7e288dee93408949adf/raw/Update-ModuleManifest.ps1'))

        #Force AppVeyor to download nuget-AnyCpu.exe (not the best way to do this but it works)
        Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

        #Check if script is running on Appveyor or offline.
        if (! ($ENV:APPVEYOR))
        {
            Function New-Version {
                Param([Version]$Version)
                if ($Version.Major -lt 0)    { [int]$Major = 0 } else { [int]$Major = $Version.Major }
                if ($Version.Minor -lt 0)    { [int]$Minor = 0 } else { [int]$Minor = $Version.Minor }
                if ($Version.Build -lt 0)    { [int]$Build = 0 } else { [int]$Build = $Version.Build }
                if ($Version.Revision -lt 0) { [int]$Revision = 0 } else { [int]$Revision = $Version.Revision }
                $Revision++
                Return ("{0}.{1}.{2}.{3}" -f $Major, $Minor, $Build, $Revision)
            }

            #Initializing APPVEYOR variables when working offline for testing
            $Environment = @{}
            $Environment.APPVEYOR_BUILD_FOLDER = "D:\PowerShell\Tests\Proxx.TEST"
            $Environment.APPVEYOR_PROJECT_NAME = Split-Path $Environment.APPVEYOR_BUILD_FOLDER -Leaf
            $Environment.APPVEYOR_BUILD_VERSION = New-Version -Version (Test-ModuleManifest -Path (Join-Path $Environment.APPVEYOR_BUILD_FOLDER -ChildPath $($Environment.APPVEYOR_PROJECT_NAME + ".psd1")) | Select-Object -ExpandProperty Version)
            $Environment.access_token = $api
            Write-Host "Initializing Environment..."
            ForEach($Var in $Environment.GetEnumerator()) { 
                Set-Item -Path ("ENV:" + $Var.Name)  -Value $Var.Value
            }
        }

        #Set ModulePath variable
        $ModulePath = [System.Environment]::GetEnvironmentVariable("PSModulePath","User")
    }
    Process {
        #Update Module Version
        Update-ModuleManifest -Path $($ENV:APPVEYOR_BUILD_FOLDER + "\$ENV:APPVEYOR_PROJECT_NAME.psd1") -ModuleVersion $ENV:APPVEYOR_BUILD_VERSION        
    

        
        #Create Module folder
        if (-Not (Test-Path -Path "$ModulePath\$ENV:APPVEYOR_PROJECT_NAME\")) { New-Item -ItemType dir -Path "$ModulePath\$ENV:APPVEYOR_PROJECT_NAME\" | Out-Null } 

        #Copy Module files
        Copy-Item -Include "*.ps1", "*.ps?1", "LICENSE", "*.dll" -Path $("$ENV:APPVEYOR_BUILD_FOLDER\*") -Destination "$ModulePath\$ENV:APPVEYOR_PROJECT_NAME\" -Force

        #Publish module to powershellgallery repository
        Publish-Module -Name $($ENV:APPVEYOR_PROJECT_NAME) -Repository $Repository -NuGetApiKey $($env:access_token) -Confirm:$false
    }
    End {
        if (!($ENV:APPVEYOR))
        {
            Write-Host "Cleaning Environment..."
            ForEach($Var in $Environment.GetEnumerator()) { 
                Remove-Item -Path ("ENV:" + $Var.Name)
            }
        }
    }
}
AppVeyor-Deploy