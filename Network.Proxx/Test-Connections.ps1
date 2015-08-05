Function Test-Connections {
	<#
		.SYNOPSIS
			Sends ICMP echo request packets ("pings") to one or more computers in a multithreaded way.

		.DESCRIPTION
			Sends ICMP echo request packets ("pings") to one or more computers in a multithreaded way.

		.EXAMPLE
			PS C:\> Test-Connections -ComputerName "192.168.1.1", "192.168.1.5", "192.168.1.7", "192.168.1.10" -Progress -Sweep

			Source    Destination IPV4Address IPV6Address Bytes Time(ms)
			------    ----------- ----------- ----------- ----- --------
			Marco-PC1 192.168.1.1                             32        0
			Marco-PC1 192.168.1.5                             32        0
			Marco-PC1 192.168.1.7                             32        0
			Marco-PC1 192.168.1.10                            32        2

		.EXAMPLE
			PS C:\> "192.168.1.1", "192.168.1.5", "192.168.1.7", "192.168.1.10" | Test-Connections

		.INPUTS
			System.Sting

		.NOTES


		.LINK
			http://www.proxx.nl/
	#>
	Param(
		[Parameter(ParameterSetName = "TestConnection")]
			[system.Management.AuthenticationLevel] $Authentication=4,
		[Parameter(ParameterSetName = "TestConnection")]
			[int] $BufferSize=32,
		[Parameter(ParameterSetName = "TestConnection", Position = 1, ValueFromPipeline=$true)]
		[Parameter(ParameterSetName = "NetPing", Position = 1, ValueFromPipeline=$true)]
			[String[]] $ComputerName,
		[Parameter(ParameterSetName = "TestConnection")]
			[int] $Count=4,
		[Parameter(ParameterSetName = "TestConnection")]
			[PSCredential] $Credential,
		[Parameter(ParameterSetName = "TestConnection")]
			[int] $Delay=1,
		[Parameter(ParameterSetName = "TestConnection")]
			[System.Management.ImpersonationLevel] $Impersonation=3,
		[Parameter(ParameterSetName = "TestConnection")]
			[Switch] $Progress,
		[Parameter(ParameterSetName = "TestConnection")]
			[Switch] $Quiet,
		[Parameter(ParameterSetName = "TestConnection", Position = 2)]
			[String[]] $Source,
		[Parameter(ParameterSetName = "TestConnection")]
		[Parameter(ParameterSetName = "NetPing")]
			[Switch] $Sweep,
		[Parameter(ParameterSetName = "TestConnection")]
			[int32]$ThrottleLimit=32,
		[Parameter(ParameterSetName = "TestConnection")]
			[int] $TimeToLive=80
	)
	
	Begin { 
		$RunspacePool = [RunspaceFactory ]::CreateRunspacePool(1, $ThrottleLimit)
		$RunspacePool.Open()
		
		[Collections.Arraylist] $Queue = @()
		
		$Params = @{}
		if ($Authentication) { 		$Params.Authentication = $Authentication }
		if ($BufferSize) { 				$Params.BufferSize = $BufferSize }
		if ($Count) {				$Params.Count = $Count }
		if ($Credential) { 			$Params.Credential = $Credential }
		if ($Delay) {			 	$Params.Delay = $Delay }
		if ($Impersonation) { 		$Params.Impersonation = $Impersonation }
		if ($Progress) { 
			[int] $Count = 0
			Write-Progress -Activity "Getting WMI Objects for class: $Class"	
		}
		if ($Quiet) { 				$Params.Quiet = $Quiet }
		if ($Source) { 				$Params.Source = $Source }
		if ($TimeToLive) { 			$Params.TimeToLive = $TimeToLive }
		
		[ScriptBlock] $ScriptBlock = {Param($Computer,$Params)			
			Return (Test-Connection -ComputerName $Computer @Params)
		}
		[Scriptblock] $PingSweep = {Param($Computer)
			$Ping=New-Object System.Net.NetworkInformation.Ping
			Try{ $Result = $Ping.Send($Computer) }
			Catch { }
			if ($Result.Status -eq "Success") {
				Write-Output ([PSCustomOBject] @{
					Source = [System.Net.Dns]::GetHostName()
					Destination = $Result.Address
					IPV4Address = ""
					IPV6Address = ""
					Bytes = $Result.Buffer.Count
					"Time(ms)" = $Result.RoundtripTime
				})
			}
		}
	}
	Process {
		ForEach($Computer in $ComputerName) {
		if ($Sweep) {
			$Job = [powershell]::Create().AddScript($PingSweep).AddArgument($Computer)
		} Else {
			$Job = [powershell]::Create().AddScript($ScriptBlock).AddArgument($Computer).AddArgument($Params)
		}
			$Job.RunspacePool = $RunspacePool
			$Queue += New-Object PSObject -Property @{
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
					if ($Progress) { Write-Progress -Activity "Sending ping's to nodes: " -Status "Progress: ($Count/$Total)" -PercentComplete (($Count/$Total)  * 100) }
					Write-Output $Job.Items.EndInvoke($Job.Status)
					$Job.Items.Dispose()
					$Queue.Remove($Job)
				}
			}
		}
		if ($Progress) { Write-Progress -Activity "Sending ping's to nodes: " -Completed }
		$RunspacePool.Close()
		$RunspacePool.Dispose()
	}
}
