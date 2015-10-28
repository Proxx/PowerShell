Function Invoke-SQL {

	param(
		[string] $ComputerName = ".\SQLEXPRESS",
		[string] $Database = "proxxdb",
        [Alias("User")]
		[string] $Username = $(throw "Please specify a User."),
        [Alias("Passw")]
		[string] $Password = $(throw "Please specify a Password."),
		[string] $Query = $(throw "Please specify a query."),
        [Switch] $ReturnObject
	)
    Begin {
	    Add-Type -AssemblyName System.Data
	    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	    #$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True"
	    $SqlConnection.ConnectionString = "Server=$ComputerName; Database=$Database; User ID=$User; Password=$Passw;"
	    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	    $SqlCmd.CommandText = $Query
	    $SqlCmd.Connection = $SqlConnection
	    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	    $SqlAdapter.SelectCommand = $SqlCmd
	    $DataTable = New-Object System.Data.DataTable
    }
    Process {
    
        $Rows = $SqlAdapter.Fill($DataTable)
    }
    End {
	    $SqlConnection.Close()
	    return @(,($DataTable))
    }
}
