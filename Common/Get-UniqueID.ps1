Function Get-UniqueID {
	Param(
	[Parameter(Mandatory=$false)]	
		[String[]]$ExcludeProperty,
	[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[PSobject]$InputObject,
	[Parameter(Mandatory=$false)]	
		[String] $Name="UniqueId",
	[Parameter(Mandatory=$false)]	
		[Switch] $PassThru,	
	[Parameter(Mandatory=$false,Position=1)]
		[String[]]$Property
	)

	Begin {
		Add-Type -assemblyname System.Web
		$SelectParam = @{}
		if ($Property) { $SelectParam.Property = [String[]]$Property }
		if ($ExcludeProperty) { $SelectParam.ExcludeProperty = $ExcludeProperty }
	}
	Process {
		ForEach($Object in $InputObject) {
			[String] $hash = ""
			[String] $String = ($Object | Select-Object @SelectParam | ft -HideTableHeaders| Out-String).replace(" ","")
			[String] $hash = [System.Web.Security.FormsAuthentication]::HashPasswordForStoringInConfigFile($string.ToString(), "MD5")
			
			if ($PassThru) { 
				$Object | Add-Member -Name $Name -Value $hash -MemberType NoteProperty 
				Write-Output $Object	
			} Else {
				Write-Output $hash
			}
		}
	}
}
