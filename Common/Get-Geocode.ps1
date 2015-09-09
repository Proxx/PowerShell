Function Get-Geocode {
	Param(
		[Parameter(ParameterSetName='Query', Mandatory=$false)]$Query = "",
		[Parameter(ParameterSetName='Address', Mandatory=$false)]$Street = "",
		[Parameter(ParameterSetName='Address', Mandatory=$false)]$City = "",
		[Parameter(ParameterSetName='Address', Mandatory=$false)]$Zip = ""
	)

	if ($Street) { $Query = $Street + " " + $City + " " + $Zip }
	$oldProgress = $progressPreference
	$progressPreference = 'silentlyContinue'
	$tmp = Invoke-WebRequest -Uri "http://open.mapquestapi.com/nominatim/v1/search?format=xml&limit=1&q=$query"
	$progressPreference = $progressPreference
	
	$Raw = [xml] $tmp.Content; $xml = [xml] $Raw.searchresults.InnerXml
	
	$Result = New-Object PSObject -Property @{   
		Latitude 	= $xml.place.lat
		Longtitude 	= $xml.place.lon
	}
	Return $Result
}
