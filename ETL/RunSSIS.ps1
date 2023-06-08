$Package=$args[0]
"Preparing to run SSIS package $Package"

$PackagePath="SSIS/" + $Package + ".dtsx"
$cfg = $Env:SSIS_Config


[xml]$xmlCfg = Get-Content -Path $cfg

"Adding Execution Log Entry"

$connectionString = $xmlCfg.DTSConfiguration.Configuration.ConfiguredValue
$connectionString = $connectionString.replace('Provider=SQLNCLI11.1;', '')


$connection = new-object system.data.SqlClient.SQLConnection($connectionString)

$sqlCommand = "EXEC Start_Log $Package"
$command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
$connection.Open()

$adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
$dataset = New-Object System.Data.DataSet
$adapter.Fill($dataSet) | Out-Null
$connection.Close()


$ExecID = $dataSet.Tables[0].Rows[0]["ID"]

"Starting Package Execution for $PackagePath"

$Log = dtexec.exe /File $PackagePath
$Log = $Log.replace("'", "''")

$RetCode = $LASTEXITCODE;

"Finished Package Execution for $PackagePath"


"Closing Execution Log Entry"

$connection = new-object system.data.SqlClient.SQLConnection($connectionString)

$sqlCommand = "EXEC Finish_Log @ID = $ExecID, @Status = $RetCode, @Log = '$Log$'"
$command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
$connection.Open()

$adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
$dataset = New-Object System.Data.DataSet
$adapter.Fill($dataSet) | Out-Null
$connection.Close()

"Execution of $Package completed with return code $RetCode"

exit $RetCode

