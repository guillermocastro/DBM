# DBM PowerShell Admin Tools
# This tool is intended to provide a Gathering Information System.
# Requirements
#   SQL Server Module - Demoted
#   Administration Rights
# V 1.0.0 02/01/2020 Guillermo Castro Initial Version
# V 2.0.0 15/06/2020 Guillermo Castro
# V 2.1.0 15/02/2021 Guillermo Castro
# V 2.1.1 13/04/2021 Guillermo Castro
$env:DBMSVR="L1-DBADEVDB-01"
$env:DBMDB="DBMDB"
$env:localDB="Admin"
$env:DBMVersion="2.1.0.0"
$env:DBMRetention="60"
$env:DBMDailyBackupLogRetention="2"
$env:DBMDailyBackupRetention="3"
$env:DBMWeeklyRetention="21"
$env:DBMMonthly="180"
$env:DBMYearly4="1461"
$env:DBMYearly7="2557"
$env:DBMBackupFolderChanges="\\vamwin\shares\SQLBackups\Changes"
$env:DBMBackupFolderDaily="\\vamwin\shares\SQLBackups\SQL Server Backups - Daily"
$env:DBMBackupFolderWeekly="\\vamwin\shares\SQLBackups\SQL Server Backups - Weekly"
$env:DBMBackupFolderMonthly="\\vamwin\shares\SQLBackups\SQL Server Backups - Monthly"
$env:DBMBackupFolder4Years="\\vamwin\shares\SQLBackups\SQL Server Backups - Annual - 4 year"
$env:DBMBackupFolder7Years="\\vamwin\shares\SQLBackups\SQL Server Backups - Annual - 7 year"
Write-Host "DDD    BBBB   M   M    222     1" -ForegroundColor Cyan
Write-Host "D  D   B   B  MM MM   2   2   11" -ForegroundColor Cyan
Write-Host "D   D  BBBB   M M M     222    1" -ForegroundColor Cyan
Write-Host "D  D   B   B  M   M    2       1" -ForegroundColor Cyan
Write-Host "DDD    BBBB   M   M   22222 .. 1" -ForegroundColor Cyan
Write-Host "Current DBM version  :" $env:DBMVersion -ForegroundColor DarkCyan
Write-Host "Current DBM server   :" $env:DBMSVR -ForegroundColor DarkCyan
Write-Host "Current DBM database :" $env:DBMDB -ForegroundColor DarkCyan 

    function Get-ConnectionString ([string]$server=$env:DBMSVR,[string]$database,[string]$username,[string]$password)
    {
        if (([string]::IsNullOrEmpty($database)))
        {
            $database=$env:DBMDB
        }
        [string]$s="Server="+$server+";"
        $s=$s+"Database="+$database+";"
        if (-not($username))
        {
            $s = $s+"Trusted_Connection=True;"
        }
        else
        {
            $s = $s+"User Id="+$username+";"+"Password="+$password+";"
        }
        return $s
    }
    function Get-DataTable
    {
    param
     (
        [string]$connectionstring,[Parameter(Mandatory=$true)][string]$sqlquery
     )
        if (-not $connectionstring) {$connectionstring=Get-ConnectionString}
        $SQLDataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SQLDataAdapter.SelectCommand = $sqlquery
        $SQLDataAdapter.SelectCommand.Connection = $connectionstring

        # create a new DataTable
        $DataTable = New-Object System.Data.DataTable;
        #fill the DataTable
        try
        {
            $RowCount=$SQLDataAdapter.Fill($DataTable)
        }
        catch
        {
            $DataTable=$null
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Host $ErrorMessage -ForegroundColor DarkYellow
            Write-Host $FailedItem -ForegroundColor DarkYellow
        }
        return @($DataTable)
        $DataTable.Dispose()
    }
    function Invoke-Transaction
    {
        param ([string]$connectionstring,[Parameter(Mandatory=$true)][string]$sqlquery)
        if (-not $connectionstring) {$connectionstring=Get-ConnectionString}
        $sqlquery=$sqlquery -replace "`t|`n|`r",""
        $SqlConn = New-Object System.Data.SqlClient.SqlConnection
        $SqlConn.ConnectionString=$connectionstring
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.CommandText = $sqlquery
        $SqlCmd.Connection=$SqlConn
        $SqlConn.Open()
        try
        {
            #Write-Host $sqlquery -ForegroundColor Yellow
            $Result = $SqlCmd.ExecuteNonQuery() | Out-Null
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Host $ErrorMessage -ForegroundColor DarkYellow
            Write-Host $FailedItem -ForegroundColor DarkYellow
        }
        $SqlConn.Close()
        return $result
    }
    function Get-InstancesList
    {
        param([switch]$active)
        $qry="SELECT [InstanceId] FROM [dbm].[Instance]"
        if ($active) {$qry=$qry+" WHERE [ServerState]='Active'"}
        $result=Get-DataTable -sqlquery $qry
        $arr=@()
        foreach($row in $result)
        {
            $arr+=$row[0]
        }
        return $arr
    }
    function Add-Device
    {
        param ([Parameter(Mandatory=$true)][string]$DeviceId)
        $datetime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
        $sqlquery="INSERT INTO [dbm].[Device] ([DeviceId],[DataimportUTC]) VALUES ('"+$DeviceId+"','"+$datetime+"')"
        Invoke-Transaction -sqlquery $sqlquery
    }
    function Get-DevicesList
    {
        $qry="SELECT [DeviceId] FROM [dbm].[Device]"
        $result=Get-DataTable -sqlquery $qry
        $arr=@()
        foreach($row in $result)
        {
            $arr+=$row[0]
        }
        return $arr
    }
    function Drop-Device
    {
        [CmdletBinding()]
        param()
        DynamicParam
        {
            # Set the dynamic parameters' name
            $ParameterName = 'DeviceId'
            
            # Create the dictionary 
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.Position = 0

            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)

            # Generate and set the ValidateSet 
            #$arrSet = Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query "SELECT InstanceId FROM [dbm].[Instance]"
            #$arrSet=@()
            $arrset=Get-DevicesList
        
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)

            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
        }
        begin 
        {
            # Bind the parameter to a friendly variable
            $DeviceId = $PsBoundParameters[$ParameterName]
        }
        process
        {
            $qry="DELETE [dbm].[Device] WHERE [DeviceId]='"+$DeviceId+"'"
            Invoke-Transaction -sqlquery $qry | Out-Null
        }
    }
    function Add-Instance
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true,position=0)][string]$InstanceId,
            [Parameter(position=1)][string]$Hostname,
            [Parameter(position=2)][string]$Port,
            [Parameter(position=3)][string]$Listener,
            [Parameter(position=4)][string]$Owner,
            [string]$Comments,
            [string]$Login,
            [string]$Password
        )
        DynamicParam
        {
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $ParameterName1 = 'DeviceId'
            
            # Create the collection of attributes
            $AttributeCollection1 = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            # Create and set the parameters' attributes
            $ParameterAttribute1 = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute1.Mandatory = $true
            $ParameterAttribute1.Position = 9

            # Add the attributes to the attributes collection
            $AttributeCollection1.Add($ParameterAttribute1)

            # Generate and set the ValidateSet 
            $arrSet1=Get-DevicesList
            $ValidateSetAttribute1 = New-Object System.Management.Automation.ValidateSetAttribute($arrSet1)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection1.Add($ValidateSetAttribute1)

            # Create and return the dynamic parameter
            $RuntimeParameter1 = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName1, [string], $AttributeCollection1)
            $RuntimeParameterDictionary.Add($ParameterName1, $RuntimeParameter1)
            #-------------------
            $ParameterName2 = 'Environment'
            
            # Create the collection of attributes
            $AttributeCollection2 = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            # Create and set the parameters' attributes
            $ParameterAttribute2 = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute2.Mandatory = $true
            $ParameterAttribute2.Position = 10

            # Add the attributes to the attributes collection
            $AttributeCollection2.Add($ParameterAttribute2)

            # Generate and set the ValidateSet 
            $arrSet2=@('Live','UAT','Test','Dev')
            $ValidateSetAttribute2 = New-Object System.Management.Automation.ValidateSetAttribute($arrSet2)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection2.Add($ValidateSetAttribute2)

            # Create and return the dynamic parameter
            $RuntimeParameter2 = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName2, [string], $AttributeCollection2)
            $RuntimeParameterDictionary.Add($ParameterName2, $RuntimeParameter2)
        

            #----------------------------
            return $RuntimeParameterDictionary
        }
        begin
        {
            $DeviceId = $PsBoundParameters[$ParameterName1]
            $Environment = $PsBoundParameters[$ParameterName2]
        }
        process
        {
    
            if (([string]::IsNullOrEmpty($InstanceId))){
                Write-Host "Please, Enter the Instance Name " -ForegroundColor Cyan -NoNewline
                $InstanceId=Read-Host
            }
            if ([string]::IsNullOrEmpty($host)){$host=$InstanceId}
            $q1="INSERT INTO [dbm].[Instance] ([InstanceId],[Hostname],[DeviceId]"
            $q2=" VALUES ('"+$InstanceId+"','"+$Hostname+"','"+$DeviceId+"'"
            if (-not ([string]::IsNullOrEmpty($Environment))){
                $q1=$q1+",[Environment]"
                $q2=$q2+",'"+$Environment+"'"
            }
            if (-not ([string]::IsNullOrEmpty($Port))){
                $q1=$q1+",[Port]"
                $q2=$q2+",'"+$Port+"'"
            }
            if (-not ([string]::IsNullOrEmpty($Listener))){
                $q1=$q1+",[Listener]"
                $q2=$q2+",'"+$Listener+"'"
            }
            if (-not ([string]::IsNullOrEmpty($Comments))){
                $q1=$q1+",[Comments]"
                $q2=$q2+",'"+$Comments.Replace("'","''")+"'"
            }
            if (-not ([string]::IsNullOrEmpty($Login))){
                $q1=$q1+",[Login]"
                $q2=$q2+",'"+$Login+"'"
            }
            if (-not ([string]::IsNullOrEmpty($Password))){
                $q1=$q1+",[Password]"
                $q2=$q2+",ENCRYPTBYPASSPHRASE(@@SERVERNAME,'"+$Password.Replace("'","''")+"')"
            }
            $q1=$q1+",[DataimportUTC])"
            $q2=$q2+",GETUTCDATE())"
            $query=$q1+$q2
            Invoke-Transaction -sqlquery $query
        }
    }

    function Drop-Instance
    {
        [CmdletBinding()]
        param()
        DynamicParam
        {
            # Set the dynamic parameters' name
            $ParameterName = 'InstanceId'
            
            # Create the dictionary 
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.Position = 0

            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)

            # Generate and set the ValidateSet 
            #$arrSet = Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query "SELECT InstanceId FROM [dbm].[Instance]"
            #$arrSet=@()
            $arrset=Get-InstancesList
        
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)

            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
        }
        begin 
        {
            # Bind the parameter to a friendly variable
            $InstanceId = $PsBoundParameters[$ParameterName]
        }
        process
        {
            $qry="DELETE [dbm].[Instance] WHERE [DeviceId]='"+$InstanceId+"'"
            Invoke-Transaction -sqlquery $qry | Out-Null
        }
    }
    function Test-Instance
    {
        [CmdletBinding()]
        param(
        )
        DynamicParam 
        {
            # Set the dynamic parameters' name
            $ParameterName = 'InstanceId'
            
            # Create the dictionary 
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.Position = 0

            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)

            # Generate and set the ValidateSet 
            #$arrSet = Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query "SELECT InstanceId FROM [dbm].[Instance]"
            $arrSet=Get-InstancesList
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)

            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
        }
        begin 
        {
            # Bind the parameter to a friendly variable
            $InstanceId = $PsBoundParameters[$ParameterName]
        }
        process
        {
            $sqlquery="SELECT @@SERVERNAME AS [Servername]"
            $connectionstring=Get-ConnectionString -server $instanceId -database master
            $SQLDataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
            $SQLDataAdapter.SelectCommand = $sqlquery
            $SQLDataAdapter.SelectCommand.Connection = $connectionstring
            $DataTable = New-Object System.Data.DataTable;
            #fill the DataTable
            try
            {
                $RowCount=$SQLDataAdapter.Fill($DataTable)
                return "Active"
            }
            catch
            {
                $DataTable=$null
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                Write-Host $ErrorMessage -ForegroundColor DarkYellow
                Write-Host $FailedItem -ForegroundColor DarkYellow
                
                $query="UPDATE [dbm].[Instance] SET [ServerState]='N/A' WHERE [InstanceId]='"+$InstanceId+"'"
                $connectionstring=Get-ConnectionString
                Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
                return "N/A"
            }
        }
    }
    function Update-Instance
    {
        [CmdletBinding()]
        param(
        )
        DynamicParam 
        {
            # Set the dynamic parameters' name
            $ParameterName = 'InstanceId'
            
            # Create the dictionary 
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.Position = 0

            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)

            # Generate and set the ValidateSet 
            #$arrSet = Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query "SELECT InstanceId FROM [dbm].[Instance]"
            $arrSet=Get-InstancesList
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)

            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
        }
        begin 
        {
            # Bind the parameter to a friendly variable
            $InstanceId = $PsBoundParameters[$ParameterName]
        }
        process
        {
         #   $channel=Get-Channel -InstanceId $InstanceId
            $connectionstring=Get-ConnectionString -server $InstanceId -database master
            $query="DECLARE @path NVARCHAR(4000) 
                    EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer',N'BackupDirectory', @path OUTPUT, 'no_output' 
                    SELECT cpu_count / hyperthread_ratio AS [PhysicalCPUs],
	                    CASE
		                    WHEN hyperthread_ratio = cpu_count THEN
			                    cpu_count
		                    ELSE
	                    (cpu_count / hyperthread_ratio) * ((cpu_count - hyperthread_ratio) / (cpu_count / hyperthread_ratio))
	                    END AS [Cores],
	                    CASE
		                    WHEN hyperthread_ratio = cpu_count THEN
			                    cpu_count
		                    ELSE
	                    ((cpu_count - hyperthread_ratio) / (cpu_count / hyperthread_ratio))
	                    END AS [LogicalCPUs],
	                    ISNULL(CONVERT(NVARCHAR(128),SERVERPROPERTY('MachineName'))+'\'+CONVERT(NVARCHAR(128),SERVERPROPERTY('InstanceName')),CONVERT(NVARCHAR(128),SERVERPROPERTY('MachineName'))) AS [InstanceId]
                        ,CONVERT(NVARCHAR(128),SERVERPROPERTY('MachineName')) AS [DeviceId]
                        ,@@Version AS [Version]
                        ,CONVERT(NVARCHAR(128),SERVERPROPERTY('Edition')) AS [Edition]
                        ,CONVERT(NVARCHAR(128),SERVERPROPERTY('ProductLevel')) AS [Level]
                        ,CONVERT(NVARCHAR(128),SERVERPROPERTY('ProductUpdateLevel')) AS [ProductUpdateLevel]
                        ,CONVERT(NVARCHAR(128),SERVERPROPERTY('ProductUpdateReference')) AS [ProductUpdateReference]
                        ,CONVERT(NVARCHAR(128),SERVERPROPERTY('ResourceLastUpdateDateTime')) AS [ResourceLastUpdateDateTime]
                        ,CONVERT(NVARCHAR(128),SERVERPROPERTY('ProductVersion')) AS [ProductVersion]
                        ,(SELECT service_account FROM sys.dm_server_services WHERE servicename='SQL Server (MSSQLSERVER)') AS [DBEAccount]
                        ,(SELECT service_account FROM sys.dm_server_services WHERE servicename='SQL Server Agent (MSSQLSERVER)') AS [AgentAccount]
                        ,CONVERT(NVARCHAR(128),SERVERPROPERTY('InstanceDefaultDataPath')) AS [InstanceDefaultDataPath]
                        ,CONVERT(NVARCHAR(128),SERVERPROPERTY('InstanceDefaultLogPath')) AS [InstanceDefaultLogPath]
                        ,@path AS [BackupDirectory]
                        ,'Active' AS [ServerState]
                        ,CONVERT(NVARCHAR(128),SERVERPROPERTY('IsSingleUser')) AS [IsSingleUser]
                        ,CONVERT(NVARCHAR(128),SERVERPROPERTY('Collation')) AS [Collation]
                        ,GETUTCDATE() AS [DataImportUTC]
                    FROM sys.dm_os_sys_info
                    "
                #Write-Host $query -ForegroundColor Green
                #$connectionstring=Get-ConnectionString -server $instanceId -database master
                
                $dt=Get-DataTable -connectionstring $connectionstring -sqlquery $query
                $serverstatus=Test-Instance -InstanceId $InstanceId
                if ($serverstatus -eq "Active")
                {
                    foreach ($row in $dt)
                    {
                        $query="UPDATE [dbm].[Instance] SET 
                            [Version]='"+$row.Version+"'
                            ,[Edition]='"+$row.Edition+"'
                            ,[Level]='"+$row.Level+"'
                            ,[ProductUpdateLevel]='"+$row.ProductUpdateLevel+"'
                            ,[ProductUpdateReference]='"+$row.ProductUpdateReference+"'
                            ,[ResourceLastUpdateDateTime]='"+$row.ResourceLastUpdateDateTime+"'
                            ,[ProductVersion]='"+$row.ProductVersion+"'
                            ,[DBEAccount]='"+$row.DBEAccount+"'
                            ,[AgentAccount]='"+$row.AgentAccount+"'
                            ,[InstanceDefaultDataPath]='"+$row.InstanceDefaultDataPath+"'
                            ,[InstanceDefaultLogPath]='"+$row.InstanceDefaultLogPath+"'
                            ,[BackupDirectory]='"+$row.BackupDirectory+"'
                            ,[ServerState]='"+$row.ServerState+"'
                            ,[IsSingleUser]='"+$row.IsSingleUser+"'
                            ,[Collation]='"+$row.Collation+"'
                            ,[PhysicalCPUs]="+$row.PhysicalCPUs+"
                            ,[Cores]="+$row.Cores+"
                            ,[LogicalCPUs]="+$row.LogicalCPUs+"
                            WHERE [InstanceId]='"+$InstanceId+"'
                        "
                        $connectionstring=Get-ConnectionString
                        Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
                    }
                }
                                 
        }

    }
    function Update-DB
    {
        [CmdletBinding()]
        param(
        )
        DynamicParam 
        {
            # Set the dynamic parameters' name
            $ParameterName = 'InstanceId'
            
            # Create the dictionary 
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $ParameterAttribute.Position = 0

            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)

            # Generate and set the ValidateSet 
            #$arrSet = Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query "SELECT InstanceId FROM [dbm].[Instance]"
            $arrSet=Get-InstancesList
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)

            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
        }
        begin 
        {
            # Bind the parameter to a friendly variable
            $InstanceId = $PsBoundParameters[$ParameterName]
            $datetime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
        }
        process
        {
        $query="TRUNCATE TABLE [dbm].[tmpDB]"
        $connectionstring=Get-ConnectionString
        Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
        $q="SELECT @@SERVERNAME AS InstanceId
                   ,[name] AS DBName
                   ,CASE WHEN [name] IN ('master','msdb','model') THEN 'FALSE' ELSE 'TRUE' END AS IsUserDB
                   ,[state_desc] COLLATE DATABASE_DEFAULT AS [DBState]
                ,[user_access_desc] COLLATE DATABASE_DEFAULT AS [DBUserAccess]
                ,[recovery_model_desc] COLLATE DATABASE_DEFAULT AS [DBRecovery]
                ,[collation_name] COLLATE DATABASE_DEFAULT AS [DBCollation]
                ,[compatibility_level] AS [DBCompatibility]
                ,[create_date] AS [DBCreation]
                          FROM sys.databases WHERE [name]<>'tempdb'"
        $connectionstring=Get-ConnectionString -server $InstanceId -database master
        $dy=Get-DataTable -connectionstring $connectionstring -sqlquery $q
        foreach ($r in $dt)
            {
                $d=$r.DBCreation
                $query="INSERT INTO [dbm].[tmpDB] ([InstanceId],[DBName],[IsUserDB],[DBState],[DBUserAccess],[DBRecovery],[DBCollation],[DBCompatibility],[DBCreation]) VALUES ('"+$InstanceId+"','"+$r.DBName+"','"+$r.IsUserDB+"','"+$r.DBState+"','"+$r.DBUserAccess+"','"+$r.DBRecovery+"','"+$r.DBCollation+"',"+$r.DBCompatibility+",CONVERT(DATETIME,CONVERT(NVARCHAR(64),'"+$d.toString("yyyy-MM-dd hh:mm:ss")+"')))"
                $connectionstring=Get-ConnectionString
                Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
            }
        #Merging temp table with live table
        $query="
            MERGE [dbm].[DB] T
            USING [dbm].[tmpDB] S
            ON T.InstanceId=S.InstanceId AND T.DBName=S.DBName
            WHEN MATCHED AND T.InstanceId=S.InstanceId THEN
                    UPDATE SET
                            T.IsUserDB=S.IsUserDB, T.DBState=S.DBState, T.DBUserAccess=S.DBUserAccess, T.DBRecovery=S.DBRecovery, T.DBCollation=S.DBCollation, T.DBCompatibility=S.DBCompatibility, T.DBCreation=S.DBCreation                
            WHEN NOT MATCHED BY SOURCE AND T.InstanceId='"+$InstanceId+"' THEN
                            DELETE
            WHEN NOT MATCHED BY TARGET THEN
                            INSERT ([InstanceId],[DBName],[IsUserDB],[DBState],[DBUserAccess],[DBRecovery],[DBCollation],[DBCompatibility],[DBCreation])
                            VALUES (S.[InstanceId],S.[DBName],S.[IsUserDB],S.[DBState],S.[DBUserAccess],S.[DBRecovery],S.[DBCollation],S.[DBCompatibility],S.[DBCreation])
            ;"
            $connectionstring=Get-ConnectionString
            Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
            
        }
    }
    function Get-FistDayFiscalYear
    {
        # default is today
        $date=(Get-Date).ToUniversalTime()#.ToString("yyyy-MM-dd hh:mm:ss")
        $year = $date.Year
        $month = $date.Month   
        # create a new DateTime object set to the first day of a given month and year
        $startOfYear = (Get-Date -Year $year -Month 4 -Day 2 -Hour 0 -Minute 0 -Second 0 -Millisecond 0)
        $startOfYear=$startOfYear.ToUniversalTime().ToString("yyyy-MM-dd")
        Return $startOfYear
    }
    function Get-FistDayOfMonth
    {
        # default is today
        $date=(Get-Date).ToUniversalTime()#.ToString("yyyy-MM-dd hh:mm:ss")
        $year = $date.Year
        $month = $date.Month
        # create a new DateTime object set to the first day of a given month and year
        $startOfMonth = (Get-Date -Year $year -Month $month -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0)
        # add a month and subtract the smallest possible time unit
        $endOfMonth = ($startOfMonth).AddMonths(1).AddTicks(-1)

        $date=$date.ToUniversalTime().ToString("yyyy-MM-dd")
        $startOfMonth=$startOfMonth.ToUniversalTime().ToString("yyyy-MM-dd")
        $endOfMonth=$endOfMonth.ToUniversalTime().ToString("yyyy-MM-dd")
        Return $startOfMonth
    }
    function Get-LastDayOfMonth
    {
        # default is today
        $date=(Get-Date).ToUniversalTime()#.ToString("yyyy-MM-dd hh:mm:ss")
        $year = $date.Year
        $month = $date.Month
    
        # create a new DateTime object set to the first day of a given month and year
        $startOfMonth = (Get-Date -Year $year -Month $month -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0)
        # add a month and subtract the smallest possible time unit
        $endOfMonth = ($startOfMonth).AddMonths(1).AddTicks(-1)
        $date=$date.ToUniversalTime().ToString("yyyy-MM-dd")
        $startOfMonth=$startOfMonth.ToUniversalTime().ToString("yyyy-MM-dd")
        $endOfMonth=$endOfMonth.ToUniversalTime().ToString("yyyy-MM-dd")
        Return $endOfMonth
    }
    function Get-BackupFolder
    {
        [CmdletBinding()]
        param(
        )
        DynamicParam 
        {
            # Set the dynamic parameters' name
            $ParameterName = 'InstanceId'
            
            # Create the dictionary 
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $ParameterAttribute.Position = 0

            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)

            # Generate and set the ValidateSet 
            #$arrSet = Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query "SELECT InstanceId FROM [dbm].[Instance]"
            $arrSet=Get-InstancesList
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)

            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
        }
        begin
        {
            # Bind the parameter to a friendly variable
            $InstanceId = $PsBoundParameters[$ParameterName]
            $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH_mm_ss")
        }
        process
        {
            $connectionstring=Get-ConnectionString
            $query="SELECT InstanceId, BackupDirectory FROM dbm.Instance WHERE InstanceId='"+$InstanceId+"'"
            $dt=Get-DataTable -connectionstring $connectionstring -sqlquery $query
            foreach ($row in $dt)
            {
                $folder=$row.BackupDirectory
            }
            Return $folder
        }
    }
    function Get-BackupRemoteFolder
    {
        [CmdletBinding()]
        param(
        )
        DynamicParam 
        {
            # Set the dynamic parameters' name
            $ParameterName = 'InstanceId'
            
            # Create the dictionary 
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $ParameterAttribute.Position = 0

            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)

            # Generate and set the ValidateSet 
            #$arrSet = Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query "SELECT InstanceId FROM [dbm].[Instance]"
            $arrSet=Get-InstancesList
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)

            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
        }
        begin
        {
            # Bind the parameter to a friendly variable
            $InstanceId = $PsBoundParameters[$ParameterName]
            $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH_mm_ss")
        }
        process
        {
            $connectionstring=Get-ConnectionString
            $query="SELECT DeviceId, BackupDirectory FROM dbm.Instance WHERE InstanceId='"+$InstanceId+"'"
            $dt=Get-DataTable -connectionstring $connectionstring -sqlquery $query
            foreach ($row in $dt)
            {
                $folder=$row.BackupDirectory
                $DeviceId=$row.DeviceId
            }
            $remotefolder="\\"+$DeviceId+"\"+$folder.substring(0,1)+"`$"+$folder.substring(2,$folder.length-2)
            return $remotefolder
        }
    }
    function Backup-Database
    {
        [CmdletBinding()]
        param(
            [string]$Database,
            [string]$folder,
            [string]$change,
            [switch]$move
        )
        DynamicParam 
        {
            # Set the dynamic parameters' name
            $ParameterName = 'InstanceId'
            
            # Create the dictionary 
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $ParameterAttribute.Position = 0

            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)

            # Generate and set the ValidateSet 
            #$arrSet = Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query "SELECT InstanceId FROM [dbm].[Instance]"
            $arrSet=Get-InstancesList
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)

            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
        }
        begin
        {
            # Bind the parameter to a friendly variable
            $InstanceId = $PsBoundParameters[$ParameterName]
            $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss")
        }
        process
        {
            $name="Database: "+$database
            if ([string]::IsNullOrWhitespace($change))
            {
                $description="Backup for change "+$change
                $today=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
                $lastdayofmonth=Get-LastDayOfMonth
                $firstdayofyear=Get-FistDayFiscalYear
                if ($today -eq $firstdayofyear)
                {
                    #Annual Backup
                    $description="Yearly backup"
                    $destination=$env:DBMYearly4
                }
                else
                {
                    if ($today -eq $lastdayofmonth)
                    {
                        #Monthly backup
                        $description="Monthly backup"
                        $destination=$env:DBMMonthly
                    } 
                    else
                    {
                        if ((Get-Date).DayOfWeek -eq "Friday")
                        {
                            #Weekly backup
                            $description="Weekly backup"
                            $destination=$env:DBMWeeklyRetention
                        }
                        else
                        {
                            #Daily backup
                            $description="Daily backup"
                            $destination=$env:DBMBackupFolderDaily
                        }
                    }
                }
            }
            else
            {
                $description="Change backup"
                $destination=$env:DBMBackupFolderChanges
            }
            $name=$InstanceId
            $destinationfile=$destination+"\"+$Database+"_"+$timestamp+".bak"               
            if ([string]::IsNullOrWhitespace($folder))
            {
             
                $folder=Get-BackupFolder -InstanceId $InstanceId
                $query="BACKUP DATABASE "+$Database+" TO DISK='"+$Database+"_"+$timestamp+".bak'"
            } 
            else 
            {
                $query="BACKUP DATABASE "+$Database+" TO DISK='"+$folder+"\"+$Database+"_"+$timestamp+".bak'"
            }
            $file=$folder+"\"+$Database+"_"+$timestamp+".bak"
            $query=$query+" WITH DESCRIPTION='"+$description+"', NOFORMAT, INIT,  NAME = N'"+$name+"', SKIP, NOREWIND, NOUNLOAD,  STATS = 10"
            $connectionstring=Get-ConnectionString -server $InstanceId -database master
            Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
            if ($move)
            {
                $remotefolder=Get-BackupRemoteFolder -InstanceId $InstanceId
                $remotefile=$remotefolder+"`\"+$Database+"`_"+$timestamp+".bak"
                
                $destination=$destination+"\"+$InstanceId.Replace("\","`$")
                New-Item -ItemType Directory -Force -Path $destination
                Move-Item -Path $remotefile -Destination $destination -Force
                                
            }
        }
    }
    function Backup-Instance
    {
        [CmdletBinding()]
        param(
        )
        DynamicParam 
        {
            # Set the dynamic parameters' name
            $ParameterName = 'InstanceId'
            
            # Create the dictionary 
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $ParameterAttribute.Position = 0

            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)

            # Generate and set the ValidateSet 
            #$arrSet = Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query "SELECT InstanceId FROM [dbm].[Instance]"
            $arrSet=Get-InstancesList
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)

            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
        }
        begin
        {
            # Bind the parameter to a friendly variable
            $InstanceId = $PsBoundParameters[$ParameterName]
            $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH_mm_ss")
        }
        process
        {
            $connectiostring=Get-ConnectionString
            $query="SELECT * FROM dbm.DB WHERE InstanceId='"+$InstanceId+"'"
            $dt=Get-DataTable -connectionstring $connectiostring -sqlquery $query
            foreach ($row in $dt)
            {
                $database=$row.DBName
                Backup-Database -InstanceId $InstanceId -Database $database -move
            }
        }
    }
    function Update-DBTable
    {
        [CmdletBinding()]
        param(
        )
        DynamicParam 
        {
            # Set the dynamic parameters' name
            $ParameterName = 'InstanceId'
            
            # Create the dictionary 
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $ParameterAttribute.Position = 0

            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)

            # Generate and set the ValidateSet 
            #$arrSet = Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query "SELECT InstanceId FROM [dbm].[Instance]"
            $arrSet=Get-InstancesList
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)

            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
        }
        begin
        {
            # Bind the parameter to a friendly variable
            $InstanceId = $PsBoundParameters[$ParameterName]
            $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH_mm_ss")
        }
        process
        {
            #Write-Host "Update-DBTable" -ForegroundColor Yellow
            $connectionstring=Get-ConnectionString -server $InstanceId -database master
            #Write-Host $connectionstring -ForegroundColor DarkMagenta
            $query="SELECT [name],[database_id] FROM sys.databases WHERE [name] NOT IN ('tempDB','model','msdb','master')"
            $dt1=Get-DataTable -connectionstring $connectionstring -sqlquery $query
            #Write-Host $query -ForegroundColor Yellow
            foreach ($r1 in $dt1)
            {
                #Write-Host $r1.name -ForegroundColor Cyan
                #Write-Host $r1.name -ForegroundColor Cyan
                $query="SELECT '[' + sc.[name] + '].[' + s.[name] + ']' AS [Table] FROM sysobjects s INNER JOIN sys.schemas sc ON s.[uid] = sc.schema_id WHERE s.xtype='U'"
                #Write-Host $query -ForegroundColor Green
                try
                {
                    #$dt2=Invoke-Sqlcmd -ServerInstance $InstanceId -Database $r1.name -Query $query -ErrorAction Stop
                    $database=$r1.name
                    $connectionstring2=Get-ConnectionString -server $InstanceId -database $database
                    #Write-Host $connectionstring2 -ForegroundColor Green
                    $dt2=Get-DataTable -connectionstring $connectionstring2 -sqlquery $query
                    #$dt2 | Out-GridView
                    foreach($r2 in $dt2)
                    {
                        $table=($r2.table).Replace("'","''")
                        #Write-Host $table -ForegroundColor Yellow
                        #Write-Host $r2.table -ForegroundColor Green
                        $query="EXEC sp_spaceused '"+$table+"'"
                        #$dt3=Invoke-Sqlcmd -ServerInstance $InstanceId -Database $r1.name -Query $query -ErrorAction Stop
                        $connectionstring3=Get-ConnectionString -server $InstanceId -database $database
                        $dt3=Get-DataTable -connectionstring $connectionstring3 -sqlquery $query
                        foreach ($r3 in $dt3)
                        {
                            $query="INSERT INTO [dbm].[DBTable] ([InstanceId],[DBName],[name],[rows],[reserved],[data],[index_size],[unused],[DataImportUTC]) VALUES ('"+$InstanceId+"','"+$r1.name+"','"+$table+"',RTRIM('"+$r3.rows+"'),'"+$r3.reserved+"','"+$r3.data+"','"+$r3.index_size+"','"+$r3.unused+"',GETUTCDATE())"
                            #Write-Host $query -ForegroundColor Cyan
                            #Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
                            $connectionstring=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
                            
                            $r=Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
                        }
                    }
                }
                catch
                {
                    Write-Host $query -ForegroundColor Yellow 
                }
            }
        }
    }
    function Update-Device{}
    function Set-BackupFolder{}
    function Install-ClientObjects{}  
    function Get-Host{}
    function Update-Disk{}

   
    function Update-SQLBackup{}
    function Update-SQLRestore{}
    function Update-SQLJob{}
    function Update-SQLJobHistory{}
    function Update-SQLSchedule{}
    function Update-SQLStep{}
    function Update-SQLOperator{}
    function Update-SQLProfile{}
    function Update-SQLMailAccount{}
    function Update-SQLLogin{}
    function Update-SQLDisk{}
    function Update-SQLRAM{}
    function Update-SQLCPU{}
    
    function Get-Port{}
    function Get-Device{}
    function Update-GDPRInfo{}
    function Update-Configuration{}
    function Update-Instances
    {
        param(
            [switch]$all=$false
        )
        $connectionstring=Get-ConnectionString
        $dt=Get-InstancesList -active
        foreach ($row in $dt)
        {
            Write-Host "Updating"$row -ForegroundColor White -NoNewline
            Update-Instance -InstanceId $row
            if ($all) {
                Update-DB -InstanceId $row
                Update-DBFile -InstanceId $row
                Update-DBTable -InstanceId $row
            }
            Write-Host " Instance" -ForegroundColor Cyan
        }
    }
