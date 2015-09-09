<#
    .Synopsis
        Install Modules
    .NOTES
        Author: Proxx
        Web:	www.Proxx.nl 
        Date:	27-08-2015
#>

Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted 
Install-Module -Name "Pester","PSScriptAnalyzer" -Scope CurrentUser
