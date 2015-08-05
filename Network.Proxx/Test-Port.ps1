Function Test-Port {
<#
	.SYNOPSIS
		Test TCP and UDP Ports on Remote Computer
	.DESCRIPTION
		Test TCP and UDP Ports on remote computers multi threaded

	.INPUTS
		System.String,System.Int32

	.OUTPUTS
		System.String

	.NOTES

		Author: Proxx
		Web:	www.Proxx.nl 
		Date:	10-06-2015

	.LINK
		http://www.proxx.nl/Wiki/Test-Port/

#>
	Param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[string[]] $ComputerName,
		[String[]] $TCP,
		[String[]] $UDP,
		[System.TimeSpan]$TimeOut = [System.TimeSpan]::FromMilliseconds(80)
	)
	
	ForEach($Computer in $ComputerName) {
		$prt = @()
		ForEach($port in $TCP) {
			try {
				$sw = [Diagnostics.Stopwatch]::StartNew()
				$Object = [PSCustomObject] @{
					Node = $Computer
					Port = $port
					Elapsed = ""
					Type = "TCP"
					State = "Closed"
				}
				While($sw.elapsed -lt $TimeOut) {
					$socket = New-object System.Net.Sockets.TcpClient($Computer, $port)
					If($socket.Client.Connected) {
						$Object.State = "Open"
						$Object.Elapsed = $sw.Elapsed.Milliseconds
						$socket.Close() 
						break
					}
				}
				if ($Object.State -ne "Open") {	$Object.Elapsed = $sw.Elapsed.Milliseconds }
			} Catch {}
			$sw.Stop()
			Write-Output $Object
		}
		ForEach($port in $UDP) {
			try { 
				$sw = [Diagnostics.Stopwatch]::StartNew()
				$Object = [PSCustomObject] @{
					Node = $Computer
					Port = $port
					Elapsed = ""
					Type = "UDP"
					State = "Closed"
				}
				While($sw.elapsed -lt $TimeOut) {
					$Global:Socket = New-object System.Net.Sockets.UdpClient
					$socket.Client.ReceiveTimeout = 80
					$socket.Client.connect($Computer, $port)
					If($socket.Client.Connected) {
						$Object.State = "Open"
						$Object.Elapsed = $sw.Elapsed.Milliseconds
						$socket.Close() 
						break
					}
				}
				if ($Object.State -ne "Open") {	$Object.Elapsed = $sw.Elapsed.Milliseconds }
			} Catch {}
			$sw.Stop()
			Write-Output $Object
		}		
	}
}
