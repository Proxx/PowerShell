Function Invoke-MySQL {
	Param(
		[Parameter(
		Mandatory = $true,
		ParameterSetName = '',
		ValueFromPipeline = $true)]
		[string]$Query,
		[Parameter(Mandatory = $true)][string]$User,
		[Parameter(Mandatory = $true)][String]$Passw,
		[Parameter(Mandatory = $true)][String]$Server,
		[Parameter(Mandatory = $true)][String]$Database,
		[String]$Port = 3306
	)
	$ConnectionString = "server=" + $Server + ";port=3306;uid=" + $User + ";pwd=" + $Passw + ";database=" + $Database

	Try {
		[void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
		$Connection = New-Object MySql.Data.MySqlClient.MySqlConnection($ConnectionString)
		$Connection.Open()

		$Command = New-Object MySql.Data.MySqlClient.MySqlCommand($Query, $Connection)
		$DataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
		$DataSet = New-Object System.Data.DataSet
		$RecordCount = $DataAdapter.Fill($DataSet, "data")
		$DataSet.Tables[0]
	}

	Catch {
		$_
	}

	Finally {
		$Connection.Close()
	}
}
