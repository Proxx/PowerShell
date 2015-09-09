Function Format-Matrix {
	Param(
	
	 [Parameter(Position=0, Mandatory=$True, ValueFromPipeline=$True)]	$InputObject,
		[parameter(Mandatory = $true)]$x,
		[parameter(Mandatory = $true)]$y,
		[parameter(Mandatory = $false)][switch]$Boolean,
		[parameter(Mandatory = $false)][Array]$Static
	)
	Begin {  }
	Process {

		$HashTable = $InputObject | Group-Object $y -AsHashTable
		$Groups = (($HashTable.Values.$x) | select -Unique)
		
		ForEach($Key in $HashTable.Keys) {
			
			$Object = New-Object PSObject
			$Object | Add-Member -MemberType NoteProperty -Name $y -Value $Key
			
			ForEach($item in $Static) { $Object | Add-Member -MemberType NoteProperty -Name $Item -Value ((($HashTable.$Key).$Item) | Select -First 1 ) }
			
			ForEach($Group in $Groups) {
				#Write-Host "." -NoNewline
				if ($Boolean) { 
					if ((($HashTable.$Key).$x) -contains $Group) { $Object | Add-Member -MemberType NoteProperty -Name $Group -Value $true } Else { $Object | Add-Member -MemberType NoteProperty -Name $Group -Value $false }
				} else {
					if ((($HashTable.$Key).$x) -contains $Group) { $Object | Add-Member -MemberType NoteProperty -Name $Group -Value "X" } Else { $Object | Add-Member -MemberType NoteProperty -Name $Group -Value "" }
				}
			}
			Write-Output $Object
		}
	}
	End {  }
}
