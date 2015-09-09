Function Invoke-SQL {

	param(
		[string] $ComputerName = ".\SQLEXPRESS",
		[string] $Database = "proxxdb",
		[string] $User = "dataread",
		[string] $Passw = "dataread",
		[string] $Query = $(throw "Please specify a query.")
	)

	Add-Type -AssemblyName System.Data
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	#$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True"
	$SqlConnection.ConnectionString = "Server=$ComputerName; Database=$Database; User ID=$User; Password=$Passw;"
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.CommandText = $Query
	$SqlCmd.Connection = $SqlConnection
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$SqlAdapter.SelectCommand = $SqlCmd
	$DataSet = New-Object System.Data.DataSet
	$Rows = $SqlAdapter.Fill($DataSet)
	$SqlConnection.Close()

	return @(,($DataSet.Tables[0]))
}
