Function Get-WmiObjects {
	<#
		.SYNOPSIS
			Gets instances of Windows Management Instrumentation (WMI) classes in a multithreaded way.

		.DESCRIPTION
			Gets instances of Windows Management Instrumentation (WMI) classes in a multithreaded way.

		.EXAMPLE
			PS C:\> Get-WmiObjects -ComputerName "Server1", "server2", "server3" -Class Win32_ComputerSystem | ft -Autosize
			
			Domain			Manufacturer Model								Name	PrimaryOwnerName TotalPhysicalMemory
			------			------------ -----								----	---------------- -------------------
			Domain.local	HP			 ProLiant DL360e Gen8				Server1	Windows User	 8419397632
			Domain.local	NEC			 Express5800/120Rh-1 [N8100-xxxxF]	Server2	Windows User	 17177952256
			Domain.local	HP			 ProLiant DL360e Gen8				Server3	Windows User	 8419397632

		.EXAMPLE
			PS C:\> "computer1", "server2" | Get-WmiObjects -Class Win32_ComputerSystem

		.INPUTS
			System.Sting

		.NOTES


		.LINK
			http://www.proxx.nl/
	#>
	Param(
		[Switch] $Amended,
		[System.Management.AuthenticationLevel]$Authentication,
		[String] $Authority,
		[Parameter(Mandatory=$true, Position=1)][String]$Class,
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)] [String[]] $ComputerName,
		[PSCredential]$Credential,
		[Switch] $DirectRead,
		[Switch] $EnableAllPrivileges,
		[String] $Filter,
		[System.Management.ImpersonationLevel] $Impersonation,
		[Switch] $List,
		[String] $Locale,
		[String] $Namespace,
		[Switch] $Progress,
		[Parameter(Position=2)][String[]] $Property,
		[String] $Query,
		[Switch] $Recurse,
		[int32]$ThrottleLimit=10
	)
	
	Begin { 
		$RunspacePool = [RunspaceFactory ]::CreateRunspacePool(1, $ThrottleLimit)
		$RunspacePool.Open()
		
		[Collections.Arraylist] $Queue = @()
		
		$Params = @{}
		if ($Amended) { 			$Params.Amended = $Amended }
		if ($Authentication) { 		$Params.Authentication = $Authentication }
		if ($Authority) { 			$Params.Authority = $Authority }
									$Params.Class = $Class
		if ($Credential) { 			$Params.Credential = $Credential }
		if ($DirectRead) {			$Params.DirectRead = $DirectRead }
		if ($EnableAllPrivileges) { $Params.EnableAllPrivileges = $EnableAllPrivileges }
		if ($Filter) { 				$Params.Filter = $Filter }
		if ($Impersonation) { 		$Params.Impersonation = $Impersonation }
		if ($List) { 				$Params.List = $List }
		if ($Locale) { 				$Params.Locale = $Locale }
		if ($Namespace) { 			$Params.Namespace = $Namespace }
		if ($Progress) { 
			[int] $Count = 0
			Write-Progress -Activity "Getting WMI Objects for class: $Class"	
		}
		if ($Property) { 			$Params.Property = $Property }
		if ($Query) { 				$Params.Query = $Query }
		if ($Recurse) { 			$Params.Recurse = $Recurse }

		
		[ScriptBlock] $ScriptBlock = {Param($Computer,$Params)			
			if (Test-Connection -Count 1 -ComputerName $Computer -Quiet) { return (Get-WmiObject -ComputerName $Computer @Params) }
		}
		
	}
	Process {
		ForEach($Computer in $ComputerName) {
			$Job = [powershell]::Create().AddScript($ScriptBlock).AddArgument($Computer).AddArgument($Params)
			$Job.RunspacePool = $RunspacePool
			$Queue += New-Object -TypeName PSObject -Property @{
				Items = $Job
				Status = $Job.BeginInvoke()
			}
		}
	}
	End {
		$Total = $ComputerName.Count
		While($Queue){
			Foreach($Job in $Queue.ToArray()){
				If($Job.Status.IsCompleted){
					$Count++
					if ($Progress) { Write-Progress -Activity "Getting WMI Objects for class: $Class" -Status "Progress: ($Count/$Total)" -PercentComplete (($Count/$Total)  * 100) }
					Write-Output -InputObject $Job.Items.EndInvoke($Job.Status)
					$Job.Items.Dispose()
					$Queue.Remove($Job)
				}
			}
		}
		if ($Progress) { Write-Progress -Activity "Getting WMI Objects for class: $Class" -Completed }
		$RunspacePool.Close()
		$RunspacePool.Dispose()
	}
}
