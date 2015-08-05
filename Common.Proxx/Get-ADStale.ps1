Function Get-ADStale {
	<#
		.DESCRIPTION
			Get stale objects from Active directory

		.PARAMETER  Computers
			Return Computer objects

		.PARAMETER  Users
			Return User objects

		.PARAMETER  Age
			Specifies date in history in days

		.EXAMPLE
			PS C:\> Get-ADStale -Users -Age 365

		.EXAMPLE
			PS C:\> Get-ADStale -Users -Age 365 | Out-GridView -PassThru | Disable-ADAccount -WhatIf
			
			This wil get all stale user objects from active directory and display them in
			a gridview when pressed ok in the gridview the accounts wil be disabled.
			
		.EXAMPLE
			PS C:\> Get-ADStale -Computers -Age 365 | Out-GridView -PassThru | Remove-ADComputer -WhatIf
			
			This wil get all stale computer objects from active directory and display them in
			a gridview when pressed ok the computer object will be removed from active directory.

		.INPUTS
			None.

		.NOTES
			www.proxx.nl

		.LINK
			www.proxx.nl/Wiki/Get-ADStale/

	#>
	[CmdletBinding()]
	Param (
		[Parameter(ParameterSetName="Computer", Mandatory=$true)]
			[Switch]$Computers,
		[Parameter(ParameterSetName="Users", Mandatory=$true)]
			[Switch]$Users,
		[Parameter(ParameterSetName="Computer",	Position=0)]
		[Parameter(ParameterSetName="Users", Position=0)]
			[int]$Age=90,
		[Parameter(ParameterSetName="Computer")]
		[Parameter(ParameterSetName="Users")]
			[Switch]$Force
		)

	$date = (Get-Date).AddDays(-$Age)
	if ($Users)
	{
		if ($Force)
		{
			$UsrFilter = "LastLogonDate -le '{0}' -OR LastLogonDate -notlike '*' -AND passwordlastset -le '{0}'" -f $Date
		} Else {
			$UsrFilter = "LastLogonDate -le '{0}' -AND Enabled -eq 'True' -OR LastLogonDate -notlike '*' -AND passwordlastset -le '{0}' -AND Enabled -eq 'True'" -f $Date
		}
		Get-ADUser -Filter $UsrFilter -Properties LastLogonDate, PasswordLastSet | Write-Output
	}
	if ($Computers)
	{
		if ($Force)
		{
			$PcFilter = "passwordlastset -le '{0}'" -f $Date
		} Else {
			$PcFilter = "PasswordLastSet -lt '{0}' -AND Enabled -eq 'True'" -f $Date
		}
		Get-ADComputer -Filter  $PcFilter -Properties PasswordLastSet | Write-Output
	}
}
