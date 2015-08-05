function Get-MacAddress {
	param( 
		[string] $Device= $( throw "Please specify device" ), 
		[Switch] $Purge
	)

	If ( $device | ? { $_ -match "[0-9].[0-9].[0-9].[0-9]" } ) { $ip = $device	} 
	Else { $ip = [System.Net.Dns]::GetHostByName($device).AddressList[0].IpAddressToString }
	If ($Purge)  { arp -d } # purge arp cache
	$ping = ( new-object System.Net.NetworkInformation.Ping ).Send($ip);
	$mac = arp -a
	if($ping) {
		( $mac | ? { $_ -match $ip } ) -match "([0-9A-F]{2}([:-][0-9A-F]{2}){5})" | out-null
		if ( $matches ) {
			Write-Output $matches[0]
		} else {
			Write-Error "Not Found"
		}
	}
}
