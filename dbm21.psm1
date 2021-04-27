# DBM PowerShell Admin Tools
# This tool is intended to provide a Gathering Information System.
# Requirements
#   SQL Server Module - Demoted
#   Administration Rights
# V 1.0.0 02/01/2020 Guillermo Castro Initial Version
# V 2.0.0 15/06/2020 Guillermo Castro
# V 2.1.0 15/02/2021 Guillermo Castro
# V 2.1.1 27/04/2021 Guillermo Castro

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

    function Get-Timestamp
    {
        return (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
    }
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
            Write-Host $ErrorMessage -ForegroundColor Yellow
            Write-Host "Called from"$((Get-PSCallStack)[1].Command) -ForegroundColor DarkYellow
            Write-Host $sqlquery -ForegroundColor White
        }
        $SqlConn.Close()
        return $result
    }
    function Get-InstancesList
    {
        param([switch]$active)
        $qry="SELECT [InstanceId] FROM [dbm].[Instance]"
        if ($active) {$qry=$qry+" WHERE [ServerState]='Active'"}
        $connectionstring=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
        $result=Get-DataTable -connectionstring $connectionstring -sqlquery $qry
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
            [string]$datetime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
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
                        ,'"+$datetime+"' AS [DataImportUTC]
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
                            ,[DataimportUTC]='"+$datetime+"'
                            WHERE [InstanceId]='"+$InstanceId+"'
                        "
                        $connectionstring=Get-ConnectionString
                        Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
                    }
                }
                                 
        }

    }
    function Get-UnusedIndex
    {
        [CmdletBinding()]
        param(
            [string]$datetime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
            ,[string]$database=""
            #,[switch]$verbose
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
            $connectionstring=Get-ConnectionString -server $InstanceId -database master
            $query="SELECT [name],[database_id] FROM sys.databases WHERE [name] NOT IN ('tempDB','model','msdb','master')"
            if ($database) {$query=$query+" AND [name]='"+$database+"'"}
            $dt1=Get-DataTable -connectionstring $connectionstring -sqlquery $query
            foreach ($r1 in $dt1)
            {
                #if ($verbose) {Write-Host $r1.name -ForegroundColor White -NoNewline}
                $q1="
                SELECT 
                    '"+$r1.name+"' AS DBName,
	                '['+S.[name]+'].['+O.[name]+']' AS DBTable,
                    '['+I.[name]+']' AS DBIndex,
                    ISNULL(UI.user_seeks,0) AS user_seeks,
                    UI.user_scans,
                    UI.user_updates,                  
                    '"+$datetime+"' AS DataImportUTC
                FROM
                    sys.dm_db_index_usage_stats UI
                    INNER JOIN sys.objects O ON UI.OBJECT_ID = O.OBJECT_ID
	                INNER JOIN sys.schemas S ON S.schema_id=O.[schema_id]
                    INNER JOIN sys.indexes I ON I.index_id = UI.index_id AND UI.OBJECT_ID = I.OBJECT_ID
                WHERE
                    UI.user_lookups = 0
                    AND
                    UI.user_seeks = 0
                    AND
                    UI.user_scans = 0
                ORDER BY
                    UI.user_updates DESC
                "
                $cs1=Get-ConnectionString -server $InstanceId -database ($r1.name)
                $dt2=Get-DataTable -connectionstring $cs1 -sqlquery $q1
                #if ($verbose) {Write-Host " done" -ForegroundColor Cyan}
                $cs2=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
                foreach ($r2 in $dt2)
                {
                    $q2="INSERT INTO dbm.UnusedIndex (InstanceId,DBName,DBTable,DBIndex,user_seeks,user_scans,user_updates,DataImportUTC) VALUES (N'"+$InstanceId+"','"+$r2.DBName+"','"+($r2.DBTable)+"','"+($r2.DBIndex)+"', "+($r2.user_seeks)+",  "+$r2.user_scans+","+($r2.user_updates)+",'"+$datetime+"')"
                    Invoke-Transaction -connectionstring $cs2 -sqlquery $q2
                }
            }
        }
    }
    function Get-IndexFragmentation
    {
        [CmdletBinding()]
        param(
            [string]$datetime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
            ,[string]$database=""
            #,[switch]$verbose
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
            $connectionstring=Get-ConnectionString -server $InstanceId -database master
            $query="SELECT [name],[database_id] FROM sys.databases WHERE [name] NOT IN ('tempDB','model','msdb','master')"
            if ($database) {$query=$query+" AND [name]='"+$database+"'"}
            $dt1=Get-DataTable -connectionstring $connectionstring -sqlquery $query
            foreach ($r1 in $dt1)
            {
                #if ($verbose) {Write-Host $r1.name -ForegroundColor White -NoNewline}
                $q1="
                    SELECT '['+S.[name]+'].['+T.[name]+']' as [DBTable],
                    '['+I.[name]+']' AS [DBIndex],
                    CONVERT(DECIMAL(10,2),DDIPS.avg_fragmentation_in_percent) AS [Fragmentation],
                    DDIPS.page_count
                    FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS DDIPS
                    INNER JOIN sys.tables T on T.object_id = DDIPS.object_id
                    INNER JOIN sys.schemas S on T.schema_id = S.schema_id
                    INNER JOIN sys.indexes I ON I.object_id = DDIPS.object_id
                    AND DDIPS.index_id = I.index_id
                    WHERE DDIPS.database_id = DB_ID()
                    and I.name is not null
                    AND DDIPS.avg_fragmentation_in_percent > 0
                    ORDER BY DDIPS.avg_fragmentation_in_percent DESC
                "
                $cs1=Get-ConnectionString -server $InstanceId -database ($r1.name)
                $dt2=Get-DataTable -connectionstring $cs1 -sqlquery $q1
                #if ($verbose) {Write-Host " done" -ForegroundColor Cyan}
                $cs2=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
                foreach ($r2 in $dt2)
                {
                    $q2="INSERT INTO [dbm].[IndexFragmentation] (InstanceId,DBName,DBTable,DBIndex,Fragmentation,page_count,DataImportUTC) VALUES (N'"+$InstanceId+"','"+($r1.name)+"','"+($r2.DBTable)+"','"+($r2.DBIndex)+"', "+($r2.Fragmentation)+",  "+$r2.page_count+",'"+$datetime+"')"
                    Invoke-Transaction -connectionstring $cs2 -sqlquery $q2
                }
            }
        }
    }
    function Get-DuplicatedIndex
    {
        [CmdletBinding()]
        param(
            [string]$datetime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
            ,[string]$database=""
            #,[switch]$verbose
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
            $connectionstring=Get-ConnectionString -server $InstanceId -database master
            $query="SELECT [name],[database_id] FROM sys.databases WHERE [name] NOT IN ('tempDB','model','msdb','master')"
            if ($database) {$query=$query+" AND [name]='"+$database+"'"}
            $dt1=Get-DataTable -connectionstring $connectionstring -sqlquery $query
            foreach ($r1 in $dt1)
            {
                #if ($verbose) {Write-Host $r1.name -ForegroundColor White -NoNewline}
                $q1="
                    ;WITH IndexColumns AS (
                        SELECT DISTINCT a.object_id, a.name, 
                                        a.type_desc, b.column_id, 
                                        TABLE_NAME=c.name, 
                                        [COL NAME]=d.name, 
                                        b.is_included_column
                        FROM sys.indexes a

                        INNER JOIN sys.index_columns b 
                                ON a.object_id = b.object_id AND a.index_id = b.index_id

                        INNER JOIN sys.tables c 
                                ON b.object_id = c.object_id

                        INNER JOIN sys.columns d 
                                ON c.object_id = d.object_id 
                               AND b.column_id = d.column_id 

                        WHERE is_hypothetical = 0

                        ),
                    CombineCols AS (

                        SELECT object_id, name, type_desc, 
                               table_name
                              ,columns=STUFF((
                                SELECT ',' + [COL NAME]
                                FROM IndexColumns b
                                WHERE a.object_id = b.object_id 
                                  AND a.name = b.name 
                                  AND a.type_desc = b.type_desc 
                                  AND a.TABLE_NAME = b.TABLE_NAME 
                                  AND b.is_included_column = 0
                                ORDER BY [COL NAME]
                                FOR XML PATH(''),TYPE).value('.', 'VARCHAR(MAX)'), 1, 1, '')
                            ,include_columns=ISNULL(STUFF((
                                SELECT ',' + [COL NAME]
                                FROM IndexColumns b
                                WHERE a.object_id = b.object_id AND 
                                    a.name = b.name AND 
                                    a.type_desc = b.type_desc AND
                                    a.TABLE_NAME = b.TABLE_NAME AND b.is_included_column = 1
                                ORDER BY [COL NAME]
                                FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 1, ''), '')
                        FROM IndexColumns a
                        GROUP BY object_id, name, type_desc, table_name)
                SELECT b.type_desc, a.table_name, a.columns, a.include_columns, b.name
                FROM (
                    SELECT table_name, columns, include_columns
                    FROM CombineCols
                    GROUP BY table_name, columns, include_columns
                    HAVING COUNT(name) > 1) a
                INNER JOIN CombineCols b 
                    ON a.table_name = b.table_name AND
                        a.columns = b.columns  AND
                        a.include_columns = b.include_columns
                ORDER BY a.table_name, a.columns
                "
                $cs1=Get-ConnectionString -server $InstanceId -database ($r1.name)
                $dt2=Get-DataTable -connectionstring $cs1 -sqlquery $q1
                #if ($verbose) {Write-Host " done" -ForegroundColor Cyan}
                $cs2=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
                foreach ($r2 in $dt2)
                {
                    $q2="INSERT INTO [dbm].[DuplicatedIndex] (InstanceId,DBName,type_desc,DBTable,Columns,include_columns,DBIndex,DataImportUTC) VALUES (N'"+$InstanceId+"','"+($r1.name)+"','"+($r2.type_desc)+"','"+($r2.DBTable)+"', '"+($r2.Columns)+"',  '"+$r2.include_columns+"','"+($r2.name)+"','"+$datetime+"')"
                    Invoke-Transaction -connectionstring $cs2 -sqlquery $q2
                }
            }
        }
    }
    function Get-MissingIndex
    {
        [CmdletBinding()]
        param(
            [string]$datetime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
            ,[string]$database=""
            #,[switch]$verbose
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
            $connectionstring=Get-ConnectionString -server $InstanceId -database master
            $query="SELECT [name],[database_id] FROM sys.databases WHERE [name] NOT IN ('tempDB','model','msdb','master')"
            if ($database) {$query=$query+" AND [name]='"+$database+"'"}
            $dt1=Get-DataTable -connectionstring $connectionstring -sqlquery $query
            foreach ($r1 in $dt1)
            {
                #if ($verbose) {Write-Host $r1.name -ForegroundColor White -NoNewline}
                $q1="
                    SELECT 
	                    databases.[name] AS [DBName],
	                    REPLACE(dm_mid.[statement],'['+databases.[name]+'].','') AS [DBTable],
	                    dm_migs.avg_user_impact*(dm_migs.user_seeks+dm_migs.user_scans) Avg_Estimated_Impact,
	                    dm_migs.last_user_seek AS Last_User_Seek,
	                    --'['+OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id)+']' AS [DBTable],
	                    'CREATE INDEX [IX_' + OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) + '_'
	                    + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.equality_columns,''),', ','_'),'[',''),']','') 
	                    + CASE
	                    WHEN dm_mid.equality_columns IS NOT NULL
	                    AND dm_mid.inequality_columns IS NOT NULL THEN '_'
	                    ELSE ''
	                    END
	                    + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.inequality_columns,''),', ','_'),'[',''),']','')
	                    + ']'
	                    + ' ON ' + dm_mid.statement
	                    + ' (' + ISNULL (dm_mid.equality_columns,'')
	                    + CASE WHEN dm_mid.equality_columns IS NOT NULL AND dm_mid.inequality_columns 
	                    IS NOT NULL THEN ',' ELSE
	                    '' END
	                    + ISNULL (dm_mid.inequality_columns, '')
	                    + ')'
	                    + ISNULL (' INCLUDE (' + dm_mid.included_columns + ')', '') AS Create_Statement
                    FROM sys.dm_db_missing_index_groups dm_mig
	                    INNER JOIN sys.dm_db_missing_index_group_stats dm_migs
	                    ON dm_migs.group_handle = dm_mig.index_group_handle
	                    INNER JOIN sys.dm_db_missing_index_details dm_mid
	                    ON dm_mig.index_handle = dm_mid.index_handle
	                    INNER JOIN sys.databases 
	                    ON dm_mid.database_id=sys.databases.database_id
                    WHERE dm_mid.database_ID = DB_ID()
                    ORDER BY Avg_Estimated_Impact DESC
                "
                $cs1=Get-ConnectionString -server $InstanceId -database ($r1.name)
                $dt2=Get-DataTable -connectionstring $cs1 -sqlquery $q1
                #if ($verbose) {Write-Host " done" -ForegroundColor Cyan}
                $cs2=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
                foreach ($r2 in $dt2)
                {
                    $create=$r2.Create_Statement
                    $create=$create.Replace("'","''")
                    $q2="INSERT INTO [dbm].[MissingIndex] (InstanceId,DBName,Impact,Last_User_Seek,DBTable,Create_Statement,DataImportUTC) VALUES (N'"+$InstanceId+"','"+($r1.name)+"',"+($r2.Avg_Estimated_Impact)+", '"+($r2.Last_User_Seek)+"', '"+$r2.DBTable+"',  '"+$create+"','"+$datetime+"')"
                    Invoke-Transaction -connectionstring $cs2 -sqlquery $q2
                }
            }
        }
    }
    function Get-Configuration
    {
        [CmdletBinding()]
        param(
            [string]$datetime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
            ,[string]$database=""
            #,[switch]$verbose
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
            $connectionstring=Get-ConnectionString -server $InstanceId -database master
            $query="SELECT * FROM [sys].[configurations]"
            $dt=Get-DataTable -connectionstring $connectionstring -sqlquery $query
            $cs=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
            foreach ($row in $dt)
            {
                $query="INSERT INTO [dbm].[Configuration] ([configuration_id],[InstanceId],[name],[value],[minimum],[maximum],[value_in_use],[description],[is_dynamic],[is_advanced],[DataImportUTC]) VALUES ("+$row.configuration_id+",'"+$InstanceId+"','"+$row.name+"',"+$row.value+","+$row.minimum+","+$row.maximum+","+$row.value_in_use+",'"+$row.description+"','"+$row.is_dynamic+"','"+$row.is_advanced+"','"+$datetime+"')"
                Invoke-Transaction -connectionstring $cs -sqlquery $query
            }
        }
    }
    function Get-SQLDisk
    {
        [CmdletBinding()]
        param(
            [string]$datetime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
        )
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
            $ParameterAttribute.Position = 1

            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)

            # Generate and set the ValidateSet 
            #$arrSet = Get-ChildItem -Path . -Directory | Select-Object -ExpandProperty FullName
            $arrSet = Get-DevicesList
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
            # Your code goes here
            $connectionstring=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
            Write-Host "Getting Disk space on"$DeviceId -ForegroundColor White -NoNewline
            try
            {
                $dt=Get-WmiObject win32_logicaldisk -ComputerName $DeviceId | Out-Null
                foreach ($r in $dt)
                {
                    if ($r.VolumeName)
                    {
                        $volname=$r.VolumeName
                        $volname=$volname.Replace("'","''")
                    }
                    else
                    {
                        $volname=""
                    }
                    $query="INSERT INTO [dbm].[Disk] ([DeviceId],[Drive],[DriveType],[FreeSpace],[Size],[VolumeName],[DataImportUTC]) VALUES ('"+$DeviceId+"','"+$r.DeviceID+"','"+$r.DriveType+"','"+$r.FreeSpace+"','"+$r.Size+"','"+$volname+"','"+$datetime+"')"
                    Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
                }
                Write-Host " Ok" -ForegroundColor Cyan
            }
            catch
            {
                Write-Host " Failed" -ForegroundColor Red
            }
        }
    }
    function Update-DB
    {
        [CmdletBinding()]
        param(
            [string]$datetime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
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
            $arrSet=@()
            foreach($row in (Get-DataTable -connectionstring (Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB) -sqlquery "SELECT InstanceId FROM [dbm].[Instance]")) {$arrSet=$arrSet+$row.InstanceId}
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
            $clientconnectionstring=Get-ConnectionString -server $Instance -database master
            $connectionstring=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
            $query="TRUNCATE TABLE [dbm].[tmpDB]"
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
            $dt=Get-DataTable -connectionstring $clientconnectionstring -sqlquery $q
            foreach ($r in $dt)
                {
                    $d=$r.DBCreation
                    $query="INSERT INTO [dbm].[tmpDB] ([InstanceId],[DBName],[IsUserDB],[DBState],[DBUserAccess],[DBRecovery],[DBCollation],[DBCompatibility],[DBCreation]) VALUES ('"+$InstanceId+"','"+$r.DBName+"','"+$r.IsUserDB+"','"+$r.DBState+"','"+$r.DBUserAccess+"','"+$r.DBRecovery+"','"+$r.DBCollation+"',"+$r.DBCompatibility+",CONVERT(DATETIME,CONVERT(NVARCHAR(64),'"+$d.toString("yyyy-MM-dd hh:mm:ss")+"')))"
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
                Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
        }
    }
    function Update-DBFile #ojo
    {
        [CmdletBinding()]
        param(
            [string]$datetime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
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
            $ParameterAttribute.Position = 1

            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)

            # Generate and set the ValidateSet 
            #$arrSet = Get-ChildItem -Path . -Directory | Select-Object -ExpandProperty FullName
            $arrSet=@()
            foreach($row in (Get-DataTable -connectionstring (Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB) -sqlquery "SELECT InstanceId FROM [dbm].[Instance]")) {$arrSet=$arrSet+$row.InstanceId}
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
            # Your code goes here
            #Write-Host $InstanceId -Foreground Cyan
            $clientconnectionstring=Get-ConnectionString -server $InstanceId -database master
            $connectionstring=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
            $query="TRUNCATE TABLE [dbm].[tmpDBFile]"
            Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
            $q="SELECT [name],[database_id] FROM sys.databases"
            $dbs=Get-DataTable -connectionstring $clientconnectionstring -sqlquery $q
            foreach ($row in $dbs)
            {
                #Write-Host $row.DBName -ForegroundColor green

                $q="SELECT 
                           @@SERVERNAME AS [InstanceId],
                           db.[name] COLLATE DATABASE_DEFAULT AS [DBName],
                           FS.[name] COLLATE DATABASE_DEFAULT AS [DBFile],
                           CASE FS.type_desc WHEN 'ROWS' THEN 'DATA' ELSE FS.type_desc END COLLATE DATABASE_DEFAULT AS [FileType],
                           FS.physical_name COLLATE DATABASE_DEFAULT AS [PhysicalDisk],
                           CASE WHEN CONVERT(NUMERIC(30,2),(FS.max_size/128.)*8.)<0 THEN 0 ELSE CONVERT(NUMERIC(30,2),(FS.max_size/128.)*8.) END AS [MaxSizeMB],
                           CASE WHEN FS.is_percent_growth=1 THEN CONVERT(VARCHAR(10),FS.growth)+'%' ELSE CONVERT(VARCHAR(20),CONVERT(NUMERIC(20,2),FS.growth/128.))+'MB' END AS [Growth],
                           CONVERT(NUMERIC(30,2),(FS.size/128.)*8.) AS [FileSizeMB],
                           ISNULL(CONVERT(NUMERIC(20,2),fs.size/128.0 - CAST(FILEPROPERTY(fs.name, 'SpaceUsed') AS INT)/128.0),0) AS [FreeSpaceMB],
                           ISNULL(CONVERT(NUMERIC(20,2),(fs.size/128.0 - CAST(FILEPROPERTY(fs.name, 'SpaceUsed') AS INT)/128.0)/((FS.size/128.))*100),0) AS [FreeSpace%]
                    FROM sys.databases db
                    INNER JOIN  sys.master_files FS ON fs.database_id = db.database_id
                    WHERE db.[name]<>'tempdb' AND db.[name]='"+($row.Name)+"'"
                    $name=($row.Name)
                    try
                    {
                        $clientconnectionstring=Get-ConnectionString -server $InstanceId -database master
                        $dt=Get-DataTable -connectionstring $clientconnectionstring -sqlquery $q
                        #Write-Host $q -ForegroundColor DarkCyan
                        #$dt | Out-GridView
                        foreach ($r in $dt)
                        {
                            $query="INSERT INTO [dbm].[tmpDBFile] ([InstanceId],[DBName],[FileName],[FileType],[PhysicalDisk],[MaxSizeMB],[Growth],[FileSizeMB],[FreeSpaceMB],[FreeSpace%]) VALUES ('"+$r.InstanceId+"','"+$r.DBName+"','"+$r.DBFile+"','"+$r.FileType+"','"+$r.PhysicalDisk+"','"+$r.MaxSizeMB+"','"+$r.Growth+"','"+$r.FileSizeMB+"','"+$r.'FreeSpaceMB'+"','"+$r.'FreeSpace%'+"')"
                            Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
                        }
                    }
                    catch
                    {
                      Write-Host $name" has a different structure" -ForegroundColor Yellow
                      $query="INSERT INTO [dbm].[tmpDBFile] ([InstanceId],[DBName],[FileName],[FileType],[PhysicalDisk],[MaxSizeMB],[Growth],[FileSizeMB],[FreeSpaceMB],[FreeSpace%]) VALUES ('"+$InstanceId+"','"+$name+"','N/A','N/A','','0','0','0','0','0')"
                      Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
                    }
            }
            $query="MERGE [dbm].[DBFile] T
                USING [dbm].[tmpDBFile] S
                ON T.InstanceId=S.InstanceId AND T.DBName=S.DBName AND T.[FileName]=S.[FileName]
                WHEN MATCHED AND T.InstanceId=S.InstanceId THEN
                       UPDATE SET
                             T.[FileType]=S.[FileType], T.[PhysicalDisk]=S.[PhysicalDisk], T.[MaxSizeMB]=S.[MaxSizeMB], T.[Growth]=S.[Growth], T.[FileSizeMB]=S.[FileSizeMB], T.[FreeSpaceMB]=S.[FreeSpaceMB], T.[FreeSpace%]=S.[FreeSpace%],T.[DataImportUTC]='"+$datetime+"'
                WHEN NOT MATCHED BY SOURCE AND T.InstanceId='"+$InstanceId+"' THEN
                             DELETE
                WHEN NOT MATCHED BY TARGET THEN
                             INSERT ([InstanceId],[DBName],[FileName],[FileType],[PhysicalDisk],[MaxSizeMB],[Growth],[FileSizeMB],[FreeSpaceMB],[FreeSpace%],[DataImportUTC])
                             VALUES (S.[InstanceId],S.[DBName],S.[FileName],S.[FileType],S.[PhysicalDisk],S.[MaxSizeMB],S.[Growth],S.[FileSizeMB],S.[FreeSpaceMB],[FreeSpace%],'"+$datetime+"')
                ;"
            #$query 
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
    #ojo
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
    #ojo
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
    #ojo
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
            [string]$datetime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
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
                    $database=$r1.name
                    $connectionstring2=Get-ConnectionString -server $InstanceId -database $database
                    $dt2=Get-DataTable -connectionstring $connectionstring2 -sqlquery $query
                    foreach($r2 in $dt2)
                    {
                        $table=($r2.table).Replace("'","''")
                        $query="EXEC sp_spaceused '"+$table+"'"
                        $connectionstring3=Get-ConnectionString -server $InstanceId -database $database
                        $dt3=Get-DataTable -connectionstring $connectionstring3 -sqlquery $query
                        foreach ($r3 in $dt3)
                        {
                            $query="INSERT INTO [dbm].[DBTable] ([InstanceId],[DBName],[name],[rows],[reserved],[data],[index_size],[unused],[DataImportUTC]) VALUES ('"+$InstanceId+"','"+$r1.name+"','"+$table+"',RTRIM('"+$r3.rows+"'),'"+$r3.reserved+"','"+$r3.data+"','"+$r3.index_size+"','"+$r3.unused+"','"+$datetime+"')"
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
    Function Update-DBRestore
    {
        [CmdletBinding()]
        param(
            [string]$datetime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
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
            $arrSet=@()
            #aja
            foreach($row in (Get-DataTable -connectionstring (Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB) -sqlquery "SELECT InstanceId FROM [dbm].[Instance]")) {$arrSet=$arrSet+$row.InstanceId}
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
            # Your code goes here
            $connectionstring=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
            $clientconnectionstring=Get-ConnectionString -server $InstanceId -database msdb
            $query="TRUNCATE TABLE [dbm].[tmpDBRestore]"
            Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
            
            $q="SELECT 
	                    R.restore_history_id AS [Id],
	                    R.restore_date AS [RestoreDate],
	                    R.destination_database_name AS [DBName],
	                    R.[user_name] AS [UserName],
	                    R.backup_set_id,
	                    CASE R.restore_type 
		                    WHEN 'D' THEN 'Database' 
		                    WHEN 'F' THEN 'File' 
		                    WHEN 'G' THEN 'Filegroup' 
		                    WHEN 'I' THEN 'Differential' 
		                    WHEN 'L' THEN 'Log' 
		                    WHEN 'V' THEN 'Verifyonly' 
		                    ELSE 'Unknown' 
	                    END AS RestoreType,
	                    R.[replace] AS IsReplace,
	                    R.[recovery] AS IsRecovery
                    FROM 
                    msdb.dbo.restorehistory R"
            $dt=Get-DataTable -connectionstring $clientconnectionstring -sqlquery $q
            #$dt | Out-GridView
            foreach ($r in $dt){
                $query="INSERT INTO [dbm].[tmpDBRestore] ([RestoreId],[InstanceId],[RestoreDate],[DBName],[UserName],[BackupSetId],[RestoreTypeId],[Replace],[Recovery]) SELECT [RestoreId]="+$r.Id+",[InstanceId]='"+$InstanceId+"',[RestoreDate]='"+$r.RestoreDate+"',[DBName]='"+$r.DBName+"',[UserName]='"+$r.UserName+"',[BackupSetId]="+$r.backup_set_id+",[RestoreTypeId]='"+$r.RestoreTypeId+"',[Replace]='"+$r.replace+"',[Recovery]='"+$r.recovery+"'"
                Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
            }
            $query="
                MERGE [dbm].[DBRestore] T
                USING [dbm].[tmpDBRestore] S
                ON T.InstanceId=S.InstanceId AND T.RestoreId=S.RestoreId AND T.[InstanceId]=S.[InstanceId]
                WHEN NOT MATCHED BY SOURCE AND T.InstanceId='"+$InstanceId+"' THEN
                                DELETE
                WHEN NOT MATCHED BY TARGET THEN
                                INSERT ([RestoreId],[InstanceId],[RestoreDate],[DBName],[UserName],[BackupSetId],[RestoreTypeId],[Replace],[Recovery],[DataImportUTC])
                                VALUES (S.[RestoreId],S.[InstanceId],S.[RestoreDate],S.[DBName],S.[UserName],S.[BackupSetId],S.[RestoreTypeId],S.[Replace],S.[Recovery],'"+$datetime+"')
                ;"
            Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
        }
    }
    Function Update-DBBackup
    {
        [CmdletBinding()]
        param(
            [string]$datetime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss"),
            [string]$version=""
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
            $arrSet=@()
            foreach($row in (Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query "SELECT InstanceId FROM [dbm].[Instance]")) {$arrSet=$arrSet+$row.InstanceId}
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
            # Your code goes here
            $connectionstring=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
            $clientconnectionstring=Get-ConnectionString -server $InstanceId -database master
            #$channel=Get-Channel -InstanceId L1-SFGALDUAT-01
            $cleaning="DELETE dbm.DBBackup WHERE InstanceId='"+$InstanceId+"'"
            Invoke-Transaction -connectionstring $connectionstring -sqlquery $cleaning
            if ($version -eq "2012")
            {
            $query="SELECT 
	                    CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS InstanceId, 
	                    msdb.dbo.backupset.database_name AS DBName, 
	                    msdb.dbo.backupset.backup_start_date AS BackupStart, 
	                    msdb.dbo.backupset.backup_finish_date AS BackupEnd, 
						CAST(DATEDIFF(second, msdb.dbo.backupset.backup_start_date,msdb.dbo.backupset.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken,
	                    msdb.dbo.backupset.expiration_date AS ExpiryDate, 
	                    CASE msdb..backupset.type 
	                    WHEN 'D' THEN 'Full' 
	                    WHEN 'I' THEN 'Incremental' 
	                    WHEN 'L' THEN 'Log' 
	                    END AS BackupType, 
	                    msdb.dbo.backupmediaset.is_password_protected AS IsPasswordProtected,
	                    msdb.dbo.backupmediaset.is_compressed AS IsCompressed,
	                    'FALSE' AS IsEncrypted,
	                    CONVERT(DECIMAL(20,2),msdb.dbo.backupset.compressed_backup_size/1024.0) AS CompressedSizeKB,
	                    CONVERT(DECIMAL(20,2),msdb.dbo.backupset.backup_size/1024.0) AS BackupSizeKB,
	                    msdb.dbo.backupmediafamily.physical_device_name AS BackupFile, 
	                    msdb.dbo.backupset.description AS [Description],
	                    CASE msdb.dbo.backupmediafamily.device_type
	                    WHEN 2 THEN 'Disk'
	                    WHEN 5 THEN 'Tape'
	                    WHEN 9 THEN 'Azure'
	                    WHEN 105 THEN 'Backup Device'
	                    END AS device_type,
	                    msdb.dbo.backupset.first_lsn,
	                    msdb.dbo.backupset.last_lsn,
	                    msdb.dbo.backupset.checkpoint_lsn
	                    FROM msdb.dbo.backupmediafamily 
                    INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
                    INNER JOIN msdb.dbo.backupmediaset ON msdb.dbo.backupmediaset.media_set_id=msdb.dbo.backupset.media_set_id
					WHERE msdb.dbo.backupset.backup_finish_date>GETUTCDATE()-60"
            }
            else
            {
            $query="SELECT 
	                    CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS InstanceId, 
	                    msdb.dbo.backupset.database_name AS DBName, 
	                    msdb.dbo.backupset.backup_start_date AS BackupStart, 
	                    msdb.dbo.backupset.backup_finish_date AS BackupEnd, 
						CAST(DATEDIFF(second, msdb.dbo.backupset.backup_start_date,msdb.dbo.backupset.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken,
	                    msdb.dbo.backupset.expiration_date AS ExpiryDate, 
	                    CASE msdb..backupset.type 
	                    WHEN 'D' THEN 'Full' 
	                    WHEN 'I' THEN 'Incremental' 
	                    WHEN 'L' THEN 'Log' 
	                    END AS BackupType, 
	                    msdb.dbo.backupmediaset.is_password_protected AS IsPasswordProtected,
	                    msdb.dbo.backupmediaset.is_compressed AS IsCompressed,
	                    CASE WHEN msdb.dbo.backupmediaset.is_encrypted IS NULL THEN 'FALSE' ELSE 'TRUE' END AS IsEncrypted,
	                    CONVERT(DECIMAL(20,2),msdb.dbo.backupset.compressed_backup_size/1024.0) AS CompressedSizeKB,
	                    CONVERT(DECIMAL(20,2),msdb.dbo.backupset.backup_size/1024.0) AS BackupSizeKB,
	                    msdb.dbo.backupmediafamily.physical_device_name AS BackupFile, 
	                    msdb.dbo.backupset.description AS [Description],
	                    CASE msdb.dbo.backupmediafamily.device_type
	                    WHEN 2 THEN 'Disk'
	                    WHEN 5 THEN 'Tape'
	                    WHEN 9 THEN 'Azure'
	                    WHEN 105 THEN 'Backup Device'
	                    END AS device_type,
	                    msdb.dbo.backupset.first_lsn,
	                    msdb.dbo.backupset.last_lsn,
	                    msdb.dbo.backupset.checkpoint_lsn
	                    FROM msdb.dbo.backupmediafamily 
                    INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
                    INNER JOIN msdb.dbo.backupmediaset ON msdb.dbo.backupmediaset.media_set_id=msdb.dbo.backupset.media_set_id
					WHERE msdb.dbo.backupset.backup_finish_date>GETUTCDATE()-60"
            }
            $dt=Get-DataTable -connectionstring $clientconnectionstring -sqlquery $query
            foreach ($r in $dt)
            {
                $q=""
                if ([string]::IsNullOrEmpty($r.expiration_date))
                {
                    $ExpiryDate="'"+$r.ExpiryDate+"'"
                }
                else
                {
                    $ExpiryDate="NULL"
                }
                $q="INSERT INTO [dbm].[DBBackup] ([InstanceId],[DBName],[BackupStart],[BackupEnd],[TimeTaken],[ExpiryDate],[BackupType],[IsPasswordProtected],[IsCompressed],[IsEncrypted],[CompressedSizeKB],[BackupSizeKB],[BackupFile],[Description],[device_type],[first_lsn],[last_lsn],[checkpoint_lsn],[DataImportUTC]) VALUES ('"+$InstanceId+"','"+$r.DBName+"','"+$r.BackupStart+"','"+$r.BackupEnd+"','"+$r.TimeTaken+"',"+$ExpiryDate+",'"+$r.BackupType+"','"+$r.IsPasswordProtected+"','"+$r.IsCompressed+"','"+$r.IsEncrypted+"','"+$r.CompressedSizeKB+"','"+$r.BackupSizeKB+"','"+$r.BackupFile+"','"+$r.Description+"','"+$r.device_type+"','"+$r.first_lsn+"','"+$r.last_lsn+"','"+$r.checkpoint_lsn+"','"+$datetime+"')"
                Invoke-Transaction -connectionstring $connectionstring -sqlquery $q
            }
        }
    }
    function Update-SQLJob
        {
        [CmdletBinding()]
        param(
            [string]$datetime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
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
            $arrSet=@()
            $arrSet=Get-InstancesList -active
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
            # Your code goes here
            $connectionstring=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
            $clientconnectionstring=Get-ConnectionString -server $InstanceId -database master
            $query="TRUNCATE TABLE [dbm].[tmpDBJob]"
            Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
            $query="SELECT * FROM msdb.dbo.sysjobs"
            $dt=Get-DataTable -connectionstring $clientconnectionstring -sqlquery $query
            foreach ($r in $dt){
                $query="INSERT INTO [dbm].[tmpDBJob] ([InstanceId],[job_id],[originating_server_id],[name],[enabled],[description],[start_step_id],[category_id],[owner_sid],[notify_level_eventlog],[notify_level_email],[notify_level_netsend],[notify_level_page],[notify_email_operator_id],[notify_netsend_operator_id],[notify_page_operator_id],[delete_level],[date_created],[date_modified],[version_number]) VALUES ('"+$InstanceId+"','"+$r.job_id+"',"+$r.originating_server_id+",'"+$r.name+"','"+$r.enabled+"','"+($r.description).Replace("N'","'").Replace("'","''")+"',"+$r.start_step_id+","+$r.category_id+",CONVERT(VARBINARY(85),'"+$r.owner_sid+"'),"+$r.notify_level_eventlog+","+$r.notify_level_email+","+$r.notify_level_netsend+","+$r.notify_level_page+","+$r.notify_email_operator_id+","+$r.notify_page_operator_id+","+$r.notify_page_operator_id+","+$r.delete_level+",CONVERT(DATETIME,'"+$r.date_created.ToString("yyyy-MM-dd hh:mm:ss")+"'),CONVERT(DATETIME,'"+$r.date_modified.ToString("yyyy-MM-dd hh:mm:ss")+"'),"+$r.version_number+")"
                Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
            }
            
            $query="MERGE [dbm].[DBJob] T
            USING [dbm].[tmpDBJob] S
            ON T.InstanceId=S.InstanceId AND T.job_id=S.job_id
            WHEN MATCHED AND T.InstanceId=S.InstanceId THEN
                    UPDATE SET
                            T.[originating_server_id]=S.[originating_server_id],T.[name]=S.[name],T.[enabled]=S.[enabled],T.[description]=S.[description],T.[start_step_id]=S.[start_step_id],T.[category_id]=S.[category_id],T.[owner_sid]=S.[owner_sid],T.[notify_level_eventlog]=S.[notify_level_eventlog],T.[notify_level_netsend]=S.[notify_level_netsend],T.[notify_level_email]=S.[notify_level_email]
                            ,T.[notify_level_page]=S.[notify_level_page],T.[notify_email_operator_id]=S.[notify_email_operator_id],T.[notify_netsend_operator_id]=S.[notify_netsend_operator_id],T.[notify_page_operator_id]=S.[notify_page_operator_id],T.[delete_level]=S.[delete_level],T.[date_created]=S.[date_created],T.[date_modified]=S.[date_modified],T.[version_number]=S.[version_number],T.[DataImportUTC]='"+$datetime+"'
            WHEN NOT MATCHED BY SOURCE AND T.InstanceId='"+$InstanceId+"' THEN
                            DELETE
            WHEN NOT MATCHED BY TARGET THEN
                            INSERT ([InstanceId],[job_id],[originating_server_id],[name],[enabled],[description],[start_step_id],[category_id],[owner_sid],[notify_level_eventlog],[notify_level_netsend],[notify_level_email]
                            ,[notify_level_page],[notify_email_operator_id],[notify_netsend_operator_id],[notify_page_operator_id],[delete_level],[date_created],[date_modified],[version_number],[DataImportUTC])
                            VALUES (S.[InstanceId],S.[job_id],S.[originating_server_id],S.[name],S.[enabled],S.[description],S.[start_step_id],S.[category_id],S.[owner_sid],S.[notify_level_eventlog],S.[notify_level_netsend],S.[notify_level_email]
                            ,S.[notify_level_page],S.[notify_email_operator_id],S.[notify_netsend_operator_id],S.[notify_page_operator_id],S.[delete_level],S.[date_created],S.[date_modified],S.[version_number],'"+$datetime+"')
            ;" 
            Invoke-Transaction -connectionstring $connectionstring -sqlquery $query

        }
    }
    function Update-SQLJobHistory
    {
        [CmdletBinding()]
        param(
            [string]$datetime=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
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
            $arrSet=@()
            foreach($row in (Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query "SELECT InstanceId FROM [dbm].[Instance]")) {$arrSet=$arrSet+$row.InstanceId}
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
            # Your code goes here
            $connectionstring=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
            $clientconnectionstring=Get-ConnectionString -server $InstanceId -database master
            $query="TRUNCATE TABLE [dbm].[tmpDBJobHistory]"
            Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
            $q="SELECT [instance_id],[server] AS [InstanceId],[job_id],[step_id],[step_name],[sql_message_id],[sql_severity],[message],[run_status],[run_date],[run_time],[run_duration],[operator_id_emailed],[operator_id_netsent],[operator_id_paged],[retries_attempted] FROM [msdb].[dbo].[sysJobHistory]"
            $dt=Get-DataTable -connectionstring $clientconnectionstring -sqlquery $q
            #$dt | Out-GridView
            foreach ($r in $dt){
                $query="INSERT INTO [dbm].[tmpDBJobHistory] ([instance_id],[job_id],[step_id],[step_name],[sql_message_id],[sql_severity],[message],[run_status],[run_date],[run_time],[run_duration],[operator_id_emailed],[operator_id_netsent],[operator_id_paged],[retries_attempted],[server]) VALUES ("+$r.instance_id+",'"+$r.job_id+"',"+$r.step_id+",'"+($r.step_name).Replace("'","''")+"',"+$r.sql_message_id+","+$r.sql_severity+",'"+$r.message.ToString().Replace("'","''")+"',"+$r.run_status+","+$r.run_date+","+$r.run_time+","+$r.run_duration+","+$r.operator_id_emailed+","+$r.operator_id_netsent+","+$r.operator_id_paged+","+$r.retries_attempted+",'"+$InstanceId+"')"
                #Write-host $query -ForegroundColor Green
                Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
            }
            #Write-Host "[gc3].[tmpsysjobhistory]" -ForegroundColor Cyan
            $query="MERGE [dbm].[DBJobHistory] T
                USING [dbm].[tmpDBJobHistory] S
                ON T.[instance_id]=S.[instance_id] AND T.InstanceId=S.[server] AND T.job_id=S.job_id AND T.step_id=S.step_id AND T.step_name=S.step_name AND T.[run_date]=S.[run_date] AND T.[run_time]=S.[run_time]
                WHEN MATCHED AND T.InstanceId=S.[server] THEN
                        UPDATE SET
                                T.[sql_message_id]=S.[sql_message_id],T.[sql_severity]=S.[sql_severity],T.[message]=S.[message],T.[run_status]=S.[run_status],T.[run_duration]=S.[run_duration],T.[operator_id_emailed]=S.[operator_id_emailed],T.[operator_id_netsent]=S.[operator_id_netsent],T.[operator_id_paged]=S.[operator_id_paged],T.[retries_attempted]=S.[retries_attempted],T.[DataimportUTC]='"+$datetime+"'
                WHEN NOT MATCHED BY SOURCE AND T.InstanceId='"+$InstanceId+"' 
                        THEN
                                DELETE
                WHEN NOT MATCHED BY TARGET THEN
                                INSERT ([instance_id],[job_id],[step_id],[step_name],[sql_message_id],[sql_severity],[message],[run_status],[run_date],[run_time],[run_duration],[operator_id_emailed],[operator_id_netsent],[operator_id_paged],[retries_attempted],[InstanceId],[DataImportUTC])
                                VALUES (S.[instance_id], S.[job_id],S.[step_id],S.[step_name],S.[sql_message_id],S.[sql_severity],S.[message],S.[run_status],S.[run_date],S.[run_time],S.[run_duration],S.[operator_id_emailed],S.[operator_id_netsent],S.[operator_id_paged],S.[retries_attempted],S.[server],'"+$datetime+"')
                ;" 
            Invoke-Transaction -connectionstring $connectionstring -sqlquery $query
        }
    }
    #function Update-Device{}
    #function Set-BackupFolder{}
    #function Install-ClientObjects{}  
    #function Get-Host{}
    #function Update-Disk{}
    #function Update-SQLBackup{}
    #function Update-SQLRestore{}
    #function Update-SQLSchedule{}
    #function Update-SQLStep{}
    #function Update-SQLOperator{}
    #function Update-SQLProfile{}
    #function Update-SQLMailAccount{}
    #function Update-SQLLogin{}
    #function Update-SQLDisk{}
    #function Update-SQLRAM{}
    #function Update-SQLCPU{}
    #function Get-Port{}
    #function Get-Device{}
    #function Update-GDPRInfo{}
    #function Invoke-Cleanup
    function Invoke-DBMDaily
    {
        param(
        $datetime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss"),
            [switch]$verbose=$false
        )
        $q="SELECT InstanceId,CASE WHEN SUBSTRING(ProductVersion,1,2)='11' THEN '2012' ELSE '' END AS ProductVersion,Edition,ServerState FROM dbm.Instance"
        $cs=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
        $dt=Get-DataTable -connectionstring $cs -sqlquery $q
        if ($verbose) {Write-Host "Timestamp"$datetime -ForegroundColor White}
        foreach ($row in $dt)
        {
            if ($verbose) {Write-Host "Updating"$row.InstanceId -ForegroundColor White -NoNewline}
            
            Update-Instance -InstanceId $row.InstanceId -datetime $datetime
            if ($row.ServerState -eq "Active"){
                if ($row.Edition -ne "Express Edition (64-bit)")
                {
                    Update-DBRestore -InstanceId $row.InstanceId -datetime $datetime
                    $version=$row.ProductVersion
                    Update-DBBackup -InstanceId $row.InstanceId -datetime $datetime -version $version
                }
            }
            
            if ($verbose) {Write-Host " Completed" -ForegroundColor Cyan}
        }
        $q="SELECT DeviceId,OS FROM dbm.Device WHERE DeviceId IN (SELECT DeviceId FROM dbm.Instance)"
        $dt=Get-DataTable -connectionstring $cs -sqlquery $q
        if ($verbose) {Write-Host "Timestamp"$datetime -ForegroundColor White}
        foreach ($row in $dt)
        {
            if ($verbose) {Write-Host "Updating"$row -ForegroundColor White -NoNewline}
            
            Get-SQLDisk -DeviceId $row.DeviceId -datetime $datetime            
            if ($verbose) {Write-Host " Completed" -ForegroundColor Cyan}
        }
    }
    function Invoke-DBMWeekly
    {
        param(
            $datetime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss"),
            [switch]$verbose=$false
        )
        #$datetime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
        $q="SELECT InstanceId,CASE WHEN SUBSTRING(ProductVersion,1,2)='11' THEN '2012' ELSE '' END AS ProductVersion,Edition,ServerState FROM dbm.Instance"
        $cs=Get-ConnectionString -server $env:DBMSVR -database $env:DBMDB
        $dt=Get-DataTable -connectionstring $cs -sqlquery $q
        if ($verbose) {Write-Host "Timestamp"$datetime -ForegroundColor White}
        foreach ($row in $dt)
        {
            if ($verbose) {Write-Host "Updating"$row.InstanceId -ForegroundColor White -NoNewline}
            
            #Update-Instance -InstanceId $row -datetime $datetime
            #Write-Host ".DB." -ForegroundColor DarkCyan -NoNewline
            #Update-DB -InstanceId $row.InstanceId -datetime $datetime
            #Write-Host ".DBFile." -ForegroundColor DarkCyan -NoNewline
            #Update-DBFile -InstanceId $row.InstanceId -datetime $datetime
            #Write-Host ".DBTable." -ForegroundColor DarkCyan -NoNewline
            #Update-DBTable -InstanceId $row.InstanceId -datetime $datetime
            #Write-Host ".SQLJobJistory." -ForegroundColor DarkCyan -NoNewline
            #Update-SQLJobHistory -datetime $datetime -InstanceId $row.InstanceId
            Update-DBRestore -InstanceId $row.InstanceId -datetime $datetime
            Update-DBBackup -InstanceId $row.InstanceId -datetime $datetime -version $row.ProductVersion
            
            if ($verbose) {Write-Host " Completed" -ForegroundColor Cyan}
        }
    }
    function Invoke-DBMMonthly
    {
        param(
            $datetime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss"),
            [switch]$verbose=$false
        )
        $dt=Get-InstancesList
        if ($verbose) {Write-Host "Timestamp"$datetime -ForegroundColor White}
        foreach ($row in $dt)
        {
            if ($verbose) {Write-Host "Updating"$row -ForegroundColor White -NoNewline}
            Write-Host "/Get-Configuration" -ForegroundColor Green -NoNewline
            Get-Configuration -datetime $datetime -InstanceId $row
            Write-Host "/Get-MissingIndex" -ForegroundColor Green -NoNewline
            Get-MissingIndex -datetime $datetime -InstanceId $row
            Write-Host "/Get-DuplicatedIndex" -ForegroundColor Green -NoNewline
            Get-DuplicatedIndex -datetime $datetime -InstanceId $row
            Write-Host "/Get-IndexFragmentation" -ForegroundColor Green -NoNewline
            Get-IndexFragmentation -datetime $datetime -InstanceId $row
            Write-Host "/Get-UnusedIndex" -ForegroundColor Green -NoNewline
            Get-UnusedIndex -datetime $datetime -InstanceId $row
            Write-Host "/Update-SQLJob" -ForegroundColor Green -NoNewline
            Update-SQLJob -datetime $datetime -InstanceId $row
            
            if ($verbose) {Write-Host " Completed" -ForegroundColor Cyan}
        }
            

    }
    Function Test
    {
        $datetime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
        #Invoke-DBMDaily -datetime $datetime
        $cs=Get-ConnectionString -server L1-DBADEVDB-01 -database dbmdb
        $query="CREATE TABLE test.Tabla (campo NVARCHAR(100))"
        Invoke-Transaction -connectionstring $cs -sqlquery $query
    }
