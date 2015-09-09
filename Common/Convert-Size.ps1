Function Convert-Size {
	Param([Int64]$Size)
	
	switch($Size) {
		{ $_ -gt 1tb } { Return "{0:n2} TB" -f ($_ / 1tb) }
		{ $_ -ge 1gb -and $_ -lt 1tb  } { Return "{0:n2} GB" -f ($_ / 1gb) }
		{ $_ -ge 1mb -and $_ -lt 1gb } { Return "{0:n2} MB " -f ($_ / 1mb) }
		{ $_ -ge 1kb -and $_ -lt 1mb } { Return "{0:n2} KB " -f ($_ / 1Kb) }
		default { Return "{0} B " -f $_} 
 	}
}
