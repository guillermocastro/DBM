# DBM PowerShell Admin Tools
# This tool is intended to provide a Gathering Information System.
# Requirements
#   SQL Server Module
#   Administration Rights
# V 1.0.0 02/01/2020 Guillermo Castro Initial Version
# V 2.0.0 15/06/2020 Guillermo Castro

$env:DBMSVR="SK-SQLGENDB-01"
$env:DBMDB="DailyReports"
$env:localDB="Admin"
$env:DBMVersion="2.0.0.0"
$env:DBMRetention="60"
Write-Host "DDD    BBBB   M   M" -ForegroundColor Magenta
Write-Host "D  D   B   B  MM MM" -ForegroundColor Magenta
Write-Host "D   D  BBBB   M M M" -ForegroundColor Magenta
Write-Host "D  D   B   B  M   M" -ForegroundColor Magenta
Write-Host "DDD    BBBB   M   M" -ForegroundColor Magenta
Write-Host "Current DBM version :" $env:DBMVersion -ForegroundColor DarkMagenta
Write-Host "Current DBM server  :" $env:DBMSVR -ForegroundColor DarkMagenta
Write-Host "Current DBM database:" $env:DBMDB -ForegroundColor DarkMagenta

function Add-Device
{
    param(
        [String]$DeviceId
    )
    process
    {
        if (!$DeviceId)
        {
            Write-Host "DeviceId is a mandatory parameter"$DeviceId -ForegroundColor Yellow
        }
        else
        {
            $query="INSERT INTO [dbm].[Device] ([DeviceId]) VALUES ('"+$DeviceId+"')"
            Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query
        }
        
    }
}
Function Get-Channel
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
        $q="SELECT [InstanceId]+CASE ISNULL([Port],'') WHEN '' THEN '' ELSE ','+[Port] END AS [Channel] FROM [dbm].[Instance] WHERE [InstanceId]='"+$InstanceId+"'"
        $dt=Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $q
        $dt.Channel
    }
}
function Get-Device
{
    param(
        [switch]$OS,
        [switch]$RAM,
        [switch]$CPU,
        [switch]$Cores
    )
    $query="SELECT DeviceId"
    if ($OS) {$query=$query+", OS"}
    if ($RAM) {$query=$query+", RAM"}
    if ($CPU) {$query=$query+", CPU"}
    if ($Cores) {$query=$query+", Cores"}
    $query=$query+" FROM [dbm].[Device]"
    Invoke-Sqlcmd  -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query
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
        $arrSet1=@()
        foreach($row in (Get-Device)) {$arrSet1=$arrSet1+$row.DeviceId}
        $ValidateSetAttribute1 = New-Object System.Management.Automation.ValidateSetAttribute($arrSet1)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection1.Add($ValidateSetAttribute1)

        # Create and return the dynamic parameter
        $RuntimeParameter1 = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName1, [string], $AttributeCollection1)
        $RuntimeParameterDictionary.Add($ParameterName1, $RuntimeParameter1)
        #-------------------
        $ParameterName2 = 'Description'
            
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
        $Description = $PsBoundParameters[$ParameterName2]
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
        if (-not ([string]::IsNullOrEmpty($Description))){
            $q1=$q1+",[Description]"
            $q2=$q2+",'"+$Description+"'"
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
        try
        {
            Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
            Write-Host "Instance"$instanceId "successfully added." -ForegroundColor Green
        }
        catch
        {
            Write-Warning -Message $Error[0]
        }
    }

}
function Get-Instance
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
        $query="SELECT * FROM [dbm].[Instance] WHERE InstanceId='"+$InstanceId+"'"
        Invoke-Sqlcmd  -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query
    }
}
function Update-Device
{
    [CmdletBinding()]
    param(
    )
    begin
    {
        Write-Host "Update-Device Started" -ForegroundColor Gray
        $query1="SELECT DISTINCT DeviceId FROM dbm.Instance"
        $dt1=Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query1
        foreach ($row1 in $dt1)
        {
            Write-Host $row1.DeviceId -ForegroundColor Cyan
            Update-DBDisk -DeviceId $row1.DeviceId
            $query2="SELECT InstanceId FROM dbm.Instance WHERE DeviceId='"+$row1.DeviceId+"'"
            $dt2=Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query2
            foreach ($row2 in $dt2)
            {
                Write-Host $row2.InstanceId -ForegroundColor DarkCyan
                $InstanceId=$row2.InstanceId
                Update-Instance -InstanceId $InstanceId
            }
        }
    }
    end
    {
        Write-Host "Update-Device finished" -ForegroundColor Gray
    }
}
    function Update-DBFile
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
            $ParameterAttribute.Position = 1

            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)

            # Generate and set the ValidateSet 
            #$arrSet = Get-ChildItem -Path . -Directory | Select-Object -ExpandProperty FullName
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
            $channel=Get-Channel -InstanceId $InstanceId
            #Write-Host $ccs -ForegroundColor Green
            #$ccs="Server="+$env:GC3SVR+";Database="+$env:GC3DB+";Trusted_Connection=True;"#Get-CentralCS
            #Write-Host $ccs -ForegroundColor Magenta
            $query="TRUNCATE TABLE [dbm].[tmpDBFile]"
            Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
            $q="SELECT [name],[database_id] FROM sys.databases"
            $dbs=Invoke-Sqlcmd -ServerInstance $channel -Database master -Query $q -ErrorAction Stop
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
                        Write-Host $name -ForegroundColor Green
                        $dt=Invoke-Sqlcmd -ServerInstance $channel -Database ($row.Name) -Query $q -ErrorAction stop
                        #Write-Host $q -ForegroundColor DarkCyan
                        #$dt | Out-GridView
                        foreach ($r in $dt){
                            $query="INSERT INTO [dbm].[tmpDBFile] ([InstanceId],[DBName],[FileName],[FileType],[PhysicalDisk],[MaxSizeMB],[Growth],[FileSizeMB],[FreeSpaceMB],[FreeSpace%]) VALUES ('"+$r.InstanceId+"','"+$r.DBName+"','"+$r.DBFile+"','"+$r.FileType+"','"+$r.PhysicalDisk+"','"+$r.MaxSizeMB+"','"+$r.Growth+"','"+$r.FileSizeMB+"','"+$r.'FreeSpaceMB'+"','"+$r.'FreeSpace%'+"')"
                            #Write-host $query -ForegroundColor Green
                            Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
                        }
                    }
                    catch
                    {
                      Write-Host $name" has a non standard structure" -ForegroundColor Yellow
                      $query="INSERT INTO [dbm].[tmpDBFile] ([InstanceId],[DBName],[FileName],[FileType],[PhysicalDisk],[MaxSizeMB],[Growth],[FileSizeMB],[FreeSpaceMB],[FreeSpace%]) VALUES ('"+$InstanceId+"','"+$name+"','N/A','N/A','','0','0','0','0','0')"
                      Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
                    }
            }
            $query="MERGE [dbm].[DBFile] T
                USING [dbm].[tmpDBFile] S
                ON T.InstanceId=S.InstanceId AND T.DBName=S.DBName AND T.[FileName]=S.[FileName]
                WHEN MATCHED AND T.InstanceId=S.InstanceId THEN
                       UPDATE SET
                             T.[FileType]=S.[FileType], T.[PhysicalDisk]=S.[PhysicalDisk], T.[MaxSizeMB]=S.[MaxSizeMB], T.[Growth]=S.[Growth], T.[FileSizeMB]=S.[FileSizeMB], T.[FreeSpaceMB]=S.[FreeSpaceMB], T.[FreeSpace%]=S.[FreeSpace%]                
                WHEN NOT MATCHED BY SOURCE AND T.InstanceId='"+$InstanceId+"' THEN
                             DELETE
                WHEN NOT MATCHED BY TARGET THEN
                             INSERT ([InstanceId],[DBName],[FileName],[FileType],[PhysicalDisk],[MaxSizeMB],[Growth],[FileSizeMB],[FreeSpaceMB],[FreeSpace%])
                             VALUES (S.[InstanceId],S.[DBName],S.[FileName],S.[FileType],S.[PhysicalDisk],S.[MaxSizeMB],S.[Growth],S.[FileSizeMB],S.[FreeSpaceMB],[FreeSpace%])
                ;" 
            Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
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
        $datetime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
    }
process
    {
        $channel=Get-Channel -InstanceId $InstanceId
        $query="TRUNCATE TABLE [dbm].[tmpDB]"
        Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop            
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
        $dt=Invoke-Sqlcmd -ServerInstance $channel -Query $q -ErrorAction Stop            
        foreach ($r in $dt)
            {
                $d=$r.DBCreation
                $query="INSERT INTO [dbm].[tmpDB] ([InstanceId],[DBName],[IsUserDB],[DBState],[DBUserAccess],[DBRecovery],[DBCollation],[DBCompatibility],[DBCreation]) VALUES ('"+$InstanceId+"','"+$r.DBName+"','"+$r.IsUserDB+"','"+$r.DBState+"','"+$r.DBUserAccess+"','"+$r.DBRecovery+"','"+$r.DBCollation+"',"+$r.DBCompatibility+",CONVERT(DATETIME,CONVERT(NVARCHAR(64),'"+$d.toString("yyyy-MM-dd hh:mm:ss")+"')))"
                Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
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
            Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
    }
}
function Update-DBJob
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
        $channel=Get-Channel -InstanceId $InstanceId
        $query="TRUNCATE TABLE [dbm].[tmpDBJob]"
        Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
        $query="SELECT * FROM msdb.dbo.sysjobs"
        $dt=Invoke-Sqlcmd -ServerInstance $channel -Database master -Query $query -ErrorAction Stop
        #$dt=Get-DataTable -cnn $cs -query $query
        #$dt | Out-GridView
        foreach ($r in $dt){
            $query="INSERT INTO [dbm].[tmpDBJob] ([InstanceId],[job_id],[originating_server_id],[name],[enabled],[description],[start_step_id],[category_id],[owner_sid],[notify_level_eventlog],[notify_level_email],[notify_level_netsend],[notify_level_page],[notify_email_operator_id],[notify_netsend_operator_id],[notify_page_operator_id],[delete_level],[date_created],[date_modified],[version_number]) VALUES ('"+$InstanceId+"','"+$r.job_id+"',"+$r.originating_server_id+",'"+$r.name+"','"+$r.enabled+"','"+($r.description).Replace("N'","'").Replace("'","''")+"',"+$r.start_step_id+","+$r.category_id+",CONVERT(VARBINARY(85),'"+$r.owner_sid+"'),"+$r.notify_level_eventlog+","+$r.notify_level_email+","+$r.notify_level_netsend+","+$r.notify_level_page+","+$r.notify_email_operator_id+","+$r.notify_page_operator_id+","+$r.notify_page_operator_id+","+$r.delete_level+",CONVERT(DATETIME,'"+$r.date_created.ToString("yyyy-MM-dd hh:mm:ss")+"'),CONVERT(DATETIME,'"+$r.date_modified.ToString("yyyy-MM-dd hh:mm:ss")+"'),"+$r.version_number+")"
            #Write-host $query -ForegroundColor Green
            #Invoke-Transaction -cs $ccs -sqlquery $query | Out-Null
            Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
        }
            
        $query="MERGE [dbm].[DBJob] T
        USING [dbm].[tmpDBJob] S
        ON T.InstanceId=S.InstanceId AND T.job_id=S.job_id
        WHEN MATCHED AND T.InstanceId=S.InstanceId THEN
                UPDATE SET
                        T.[originating_server_id]=S.[originating_server_id],T.[name]=S.[name],T.[enabled]=S.[enabled],T.[description]=S.[description],T.[start_step_id]=S.[start_step_id],T.[category_id]=S.[category_id],T.[owner_sid]=S.[owner_sid],T.[notify_level_eventlog]=S.[notify_level_eventlog],T.[notify_level_netsend]=S.[notify_level_netsend],T.[notify_level_email]=S.[notify_level_email]
                        ,T.[notify_level_page]=S.[notify_level_page],T.[notify_email_operator_id]=S.[notify_email_operator_id],T.[notify_netsend_operator_id]=S.[notify_netsend_operator_id],T.[notify_page_operator_id]=S.[notify_page_operator_id],T.[delete_level]=S.[delete_level],T.[date_created]=S.[date_created],T.[date_modified]=S.[date_modified],T.[version_number]=S.[version_number],T.[DataImportUTC]=GETUTCDATE()
        WHEN NOT MATCHED BY SOURCE AND T.InstanceId='"+$InstanceId+"' THEN
                        DELETE
        WHEN NOT MATCHED BY TARGET THEN
                        INSERT ([InstanceId],[job_id],[originating_server_id],[name],[enabled],[description],[start_step_id],[category_id],[owner_sid],[notify_level_eventlog],[notify_level_netsend],[notify_level_email]
                        ,[notify_level_page],[notify_email_operator_id],[notify_netsend_operator_id],[notify_page_operator_id],[delete_level],[date_created],[date_modified],[version_number],[DataImportUTC])
                        VALUES (S.[InstanceId],S.[job_id],S.[originating_server_id],S.[name],S.[enabled],S.[description],S.[start_step_id],S.[category_id],S.[owner_sid],S.[notify_level_eventlog],S.[notify_level_netsend],S.[notify_level_email]
                        ,S.[notify_level_page],S.[notify_email_operator_id],S.[notify_netsend_operator_id],S.[notify_page_operator_id],S.[delete_level],S.[date_created],S.[date_modified],S.[version_number],GETUTCDATE())
        ;" 
        Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
        #Invoke-Transaction -cs $ccs -sqlquery $query | Out-Null

    }
}
function Update-DBJobHistory
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
        $channel=Get-Channel -InstanceId $InstanceId
        $query="TRUNCATE TABLE [dbm].[tmpDBJobHistory]"
        Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
        $q="SELECT [instance_id],[server] AS [InstanceId],[job_id],[step_id],[step_name],[sql_message_id],[sql_severity],[message],[run_status],[run_date],[run_time],[run_duration],[operator_id_emailed],[operator_id_netsent],[operator_id_paged],[retries_attempted] FROM [msdb].[dbo].[sysJobHistory]"
        $dt=Invoke-Sqlcmd -ServerInstance $channel -Database msdb -Query $q -ErrorAction Stop
        #$dt | Out-GridView
        foreach ($r in $dt){
            $query="INSERT INTO [dbm].[tmpDBJobHistory] ([instance_id],[job_id],[step_id],[step_name],[sql_message_id],[sql_severity],[message],[run_status],[run_date],[run_time],[run_duration],[operator_id_emailed],[operator_id_netsent],[operator_id_paged],[retries_attempted],[server]) VALUES ("+$r.instance_id+",'"+$r.job_id+"',"+$r.step_id+",'"+($r.step_name).Replace("'","''")+"',"+$r.sql_message_id+","+$r.sql_severity+",'"+$r.message.ToString().Replace("'","''")+"',"+$r.run_status+","+$r.run_date+","+$r.run_time+","+$r.run_duration+","+$r.operator_id_emailed+","+$r.operator_id_netsent+","+$r.operator_id_paged+","+$r.retries_attempted+",'"+$InstanceId+"')"
            #Write-host $query -ForegroundColor Green
            Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
        }
        #Write-Host "[gc3].[tmpsysjobhistory]" -ForegroundColor Cyan
        $query="MERGE [dbm].[DBJobHistory] T
            USING [dbm].[tmpDBJobHistory] S
            ON T.[instance_id]=S.[instance_id] AND T.InstanceId=S.[server] AND T.job_id=S.job_id AND T.step_id=S.step_id AND T.step_name=S.step_name AND T.[run_date]=S.[run_date] AND T.[run_time]=S.[run_time]
            WHEN MATCHED AND T.InstanceId=S.[server] THEN
                    UPDATE SET
                            T.[sql_message_id]=S.[sql_message_id],T.[sql_severity]=S.[sql_severity],T.[message]=S.[message],T.[run_status]=S.[run_status],T.[run_duration]=S.[run_duration],T.[operator_id_emailed]=S.[operator_id_emailed],T.[operator_id_netsent]=S.[operator_id_netsent],T.[operator_id_paged]=S.[operator_id_paged],T.[retries_attempted]=S.[retries_attempted],T.[DataimportUTC]=GETUTCDATE()                                 
            WHEN NOT MATCHED BY SOURCE AND T.InstanceId='"+$InstanceId+"' 
                    THEN
                            DELETE
            WHEN NOT MATCHED BY TARGET THEN
                            INSERT ([instance_id],[job_id],[step_id],[step_name],[sql_message_id],[sql_severity],[message],[run_status],[run_date],[run_time],[run_duration],[operator_id_emailed],[operator_id_netsent],[operator_id_paged],[retries_attempted],[InstanceId],[DataImportUTC])
                            VALUES (S.[instance_id], S.[job_id],S.[step_id],S.[step_name],S.[sql_message_id],S.[sql_severity],S.[message],S.[run_status],S.[run_date],S.[run_time],S.[run_duration],S.[operator_id_emailed],S.[operator_id_netsent],S.[operator_id_paged],S.[retries_attempted],S.[server],GETUTCDATE())
            ;" 
        Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
    }
}
Function Update-DBRestore
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
        $channel=Get-Channel -InstanceId $InstanceId
        $query="TRUNCATE TABLE [dbm].[tmpDBRestore]"
        Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
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
        $dt=Invoke-Sqlcmd -ServerInstance $channel -Database msdb -Query $q -ErrorAction Stop
        #$dt | Out-GridView
        foreach ($r in $dt){
            $query="INSERT INTO [dbm].[tmpDBRestore] ([RestoreId],[InstanceId],[RestoreDate],[DBName],[UserName],[BackupSetId],[RestoreTypeId],[Replace],[Recovery]) SELECT [RestoreId]="+$r.Id+",[InstanceId]='"+$InstanceId+"',[RestoreDate]='"+$r.RestoreDate+"',[DBName]='"+$r.DBName+"',[UserName]='"+$r.UserName+"',[BackupSetId]="+$r.backup_set_id+",[RestoreTypeId]='"+$r.RestoreTypeId+"',[Replace]='"+$r.replace+"',[Recovery]='"+$r.recovery+"'"
            #Write-host $query -ForegroundColor DarkCyan
            Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Continue
        }
        $query="
            MERGE [dbm].[DBRestore] T
            USING [dbm].[tmpDBRestore] S
            ON T.InstanceId=S.InstanceId AND T.RestoreId=S.RestoreId AND T.[InstanceId]=S.[InstanceId]
            WHEN NOT MATCHED BY SOURCE AND T.InstanceId='"+$InstanceId+"' THEN
                            DELETE
            WHEN NOT MATCHED BY TARGET THEN
                            INSERT ([RestoreId],[InstanceId],[RestoreDate],[DBName],[UserName],[BackupSetId],[RestoreTypeId],[Replace],[Recovery])
                            VALUES (S.[RestoreId],S.[InstanceId],S.[RestoreDate],S.[DBName],S.[UserName],S.[BackupSetId],S.[RestoreTypeId],S.[Replace],S.[Recovery])
            ;"
        Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
    }
}
Function Update-DBBackup
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
        $channel=Get-Channel -InstanceId $InstanceId
        $query="TRUNCATE TABLE [dbm].[tmpDBBackup]"
        Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
        #$channel=Get-Channel -InstanceId L1-SFGALDUAT-01
        $q=Invoke-Sqlcmd -ServerInstance $channel -Database master -Query "SELECT SUBSTRING(CONVERT(VARCHAR(20),SERVERPROPERTY('ProductVersion')),1,2) AS V"
        IF ($q.V -eq "11")
        {
        $query="SELECT 
	                CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS InstanceId, 
	                msdb.dbo.backupset.database_name AS DBName, 
	                msdb.dbo.backupset.backup_start_date AS BackupStart, 
	                msdb.dbo.backupset.backup_finish_date AS BackupEnd, 
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
                "
        }
        else
        {
        $query="SELECT 
	                CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS InstanceId, 
	                msdb.dbo.backupset.database_name AS DBName, 
	                msdb.dbo.backupset.backup_start_date AS BackupStart, 
	                msdb.dbo.backupset.backup_finish_date AS BackupEnd, 
	                msdb.dbo.backupset.expiration_date AS ExpiryDate, 
	                CASE msdb..backupset.type 
	                WHEN 'D' THEN 'Full' 
	                WHEN 'I' THEN 'Incremental' 
	                WHEN 'L' THEN 'Log' 
	                END AS BackupType, 
	                msdb.dbo.backupmediaset.is_password_protected AS IsPasswordProtected,
	                msdb.dbo.backupmediaset.is_compressed AS IsCompressed,
	                ISNULL(msdb.dbo.backupmediaset.is_encrypted,'FALSE') AS IsEncrypted,
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
                "
        }
        $dt=Invoke-Sqlcmd -ServerInstance $channel -Database msdb -Query $query -ErrorAction Stop
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
            $q="INSERT INTO [dbm].[tmpDBBackup] ([InstanceId],[DBName],[BackupStart],[BackupEnd],[ExpiryDate],[BackupType],[IsPasswordProtected],[IsCompressed],[IsEncrypted],[CompressedSizeKB],[BackupSizeKB],[BackupFile],[Description],[device_type],[first_lsn],[last_lsn],[checkpoint_lsn]) VALUES ('"+$InstanceId+"','"+$r.DBName+"','"+$r.BackupStart+"','"+$r.BackupEnd+"',"+$ExpiryDate+",'"+$r.BackupType+"','"+$r.IsPasswordProtected+"','"+$r.IsCompressed+"','"+$r.IsEncrypted+"','"+$r.CompressedSizeKB+"','"+$r.BackupSizeKB+"','"+$r.BackupFile+"','"+$r.Description+"','"+$r.device_type+"','"+$r.first_lsn+"','"+$r.last_lsn+"','"+$r.checkpoint_lsn+"')"
            Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $q -ErrorAction Stop
        }
        $query="
            MERGE [dbm].[DBBackup] T
            USING [dbm].[tmpDBBackup] S
            ON T.InstanceId=S.InstanceId AND T.[DBName]=S.[DBName] AND T.[BackupStart]=S.[BackupStart] AND T.[InstanceId]=S.[InstanceId]
            WHEN NOT MATCHED BY SOURCE AND T.InstanceId='"+$InstanceId+"' THEN
                            DELETE
            WHEN NOT MATCHED BY TARGET THEN
                            INSERT ([InstanceId],[DBName],[BackupStart],[BackupEnd],[ExpiryDate],[BackupType],[IsPasswordProtected],[IsCompressed],[IsEncrypted],[CompressedSizeKB],[BackupSizeKB],[BackupFile],[Description],[device_type],[first_lsn],[last_lsn],[checkpoint_lsn])
                            VALUES (S.[InstanceId],S.[DBName],S.[BackupStart],S.[BackupEnd],S.[ExpiryDate],S.[BackupType],S.[IsPasswordProtected],S.[IsCompressed],S.[IsEncrypted],S.[CompressedSizeKB],S.[BackupSizeKB],S.[BackupFile],S.[Description],S.[device_type],S.[first_lsn],S.[last_lsn],S.[checkpoint_lsn])
            ;"
        Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
    }
}
function Update-DBDisk
{
    [CmdletBinding()]
    param()
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
        $arrSet1=@()
        foreach($row in (Get-Device)) {$arrSet1=$arrSet1+$row.DeviceId}
        $ValidateSetAttribute1 = New-Object System.Management.Automation.ValidateSetAttribute($arrSet1)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection1.Add($ValidateSetAttribute1)

        # Create and return the dynamic parameter
        $RuntimeParameter1 = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName1, [string], $AttributeCollection1)
        $RuntimeParameterDictionary.Add($ParameterName1, $RuntimeParameter1)        
        #----------------------------
        return $RuntimeParameterDictionary
    }
    begin
    {
        $DeviceId = $PsBoundParameters[$ParameterName1]
    }
process 
    {
        $dt=Get-WmiObject win32_logicaldisk -ComputerName $DeviceId
        foreach ($r in $dt)
        {
            if ($r.VolumeName)
            {$volumename=$r.VolumeName}
            else
            {$volumename=""}
            $volumename=$volumename.Replace("'","''")
            $query="INSERT INTO [dbm].[Disk] ([DeviceId],[Drive],[DriveType],[ProviderName],[FreeSpace],[Size],[VolumeName],[DataImportUTC]) VALUES ('"+$DeviceId+"','"+$r.DeviceID+"','"+$r.DriveType+"','"+$r.ProviderName+"','"+$r.FreeSpace+"','"+$r.Size+"','"+$volumename+"',GETUTCDATE())"
            #Write-host $query -ForegroundColor Green
            Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
        }
    }
}
function Update-GDPRInfo
{
    $query="SELECT * FROM dbm.DB WHERE IsUserDB=1"
    $dt1=Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
    foreach ($row in $dt1)
    {
        $InstanceId=$row.InstanceId
        $DBName=$row.DBName
        Write-Host $InstanceId" - "$DBName -ForegroundColor Cyan
        $q2="SELECT ST.[name] AS TableName, SC.[name] AS ColumnName FROM sys.columns SC 
                INNER JOIN sys.tables ST ON SC.object_id=ST.object_id
                WHERE SC.[name] IN (
                'Surname'
                ,'givenname'
                ,'Address'
                ,'Phone'
                ,'email'
                ,'birth'
                ,'BOD'
                ,'NI'
                ,'Passport'
                ,'Gender'
                ,'Religion'
                ,'Sex'
                ,'Salary'
                ,'Medical','Union')
                "
        $dt2=Invoke-Sqlcmd -ServerInstance $InstanceId -Database $DBName -Query $q2 -ErrorAction Stop
        if ($dt2.count -ne 0)
        {
            Write-Host $dt2.count -ForegroundColor Yellow
            $q3="Update dbm.DB SET PersonalData='TRUE' WHERE InstanceId='"+$InstanceId+"' AND DBName='"+$DBName+"'"
        }
        else
        {
            Write-Host $dt2.count -ForegroundColor Green
            $q3="Update dbm.DB SET PersonalData='FALSE' WHERE InstanceId='"+$InstanceId+"' AND DBName='"+$DBName+"'"
        }
        Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $q3 -ErrorAction Stop
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
        $channel=Get-Channel -InstanceId $InstanceId
        $query="DECLARE @path NVARCHAR(4000) 
                    EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer',N'BackupDirectory', @path OUTPUT, 'no_output' 
                    SELECT ISNULL(CONVERT(NVARCHAR(128),SERVERPROPERTY('MachineName'))+'\'+CONVERT(NVARCHAR(128),SERVERPROPERTY('InstanceName')),CONVERT(NVARCHAR(128),SERVERPROPERTY('MachineName'))) AS [InstanceId]
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
                    ,GETUTCDATE() AS [DataImportUTC]"
            #Write-Host $query -ForegroundColor Green
            $dt=(Invoke-Sqlcmd -ServerInstance $channel -Database master -Query $query).Channel
            #$dt | Out-GridView
        #try
        #{
        
            $channel=Get-Channel -InstanceId $InstanceId
            $dt=Invoke-Sqlcmd -ServerInstance $channel -Database master -Query $query
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
                        WHERE [InstanceId]='"+$InstanceId+"'
                    "
                    Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
                    Update-DB -InstanceId $InstanceId
                    Update-DBFile -InstanceId $InstanceID
                    Update-DBJob -InstanceId $InstanceID
                    Update-DBBackup -InstanceId $InstanceID
                    Update-DBRestore -InstanceId $InstanceID
                }
        #}
        #catch
        #{
        #    Write-Warning -Message $Error[0]
        #    $query="UPDATE [dbm].[Instance] SET [ServerState]='N/A', [DataImportUTC]=GETUTCDATE() WHERE [InstanceId]='"+$InstanceId+"'"
        #    Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop            
        #}
    }
}
function Update-DBTable
{
    begin 
    {
        $datetime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
    }
            

    process 
        {
            # Your code goes here
            $query="SELECT [InstanceId],[ServerState] FROM dbm.Instance WHERE [ServerState]='Active'"
            $dt0=Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
            foreach ($r0 in $dt0)
            {
                $InstanceId=$r0.InstanceId
                $query="SELECT [name],[database_id] FROM sys.databases WHERE [name] NOT IN ('tempDB','model','msdb','master')"
                $dt1=Invoke-Sqlcmd -ServerInstance $InstanceId -Database "master" -Query $query -ErrorAction Stop
                foreach ($r1 in $dt1)
                {
                    #Write-Host $r1.name -ForegroundColor Cyan
                    $query="SELECT '[' + sc.[name] + '].[' + s.[name] + ']' AS [Table] FROM sysobjects s INNER JOIN sys.schemas sc ON s.[uid] = sc.schema_id WHERE s.xtype='U'"
                    #Write-Host $query -ForegroundColor Green
                    try
                    {
                        $dt2=Invoke-Sqlcmd -ServerInstance $InstanceId -Database $r1.name -Query $query -ErrorAction Stop
                        #$dt2 | Out-GridView
                        foreach($r2 in $dt2)
                        {
                            $table=($r2.table).Replace("'","''")
                            #Write-Host $r2.table -ForegroundColor Green
                            $query="EXEC sp_spaceused '"+$table+"'"
                            $dt3=Invoke-Sqlcmd -ServerInstance $InstanceId -Database $r1.name -Query $query -ErrorAction Stop
                            foreach ($r3 in $dt3)
                            {
                                $query="INSERT INTO [dbm].[DBTable] ([InstanceId],[DBName],[name],[rows],[reserved],[data],[index_size],[unused],[DataImportUTC]) VALUES ('"+$InstanceId+"','"+$r1.name+"','"+$table+"','"+$r3.rows+"','"+$r3.reserved+"','"+$r3.data+"','"+$r3.index_size+"','"+$r3.unused+"',GETUTCDATE())"
                                Invoke-Sqlcmd -ServerInstance $env:DBMSVR -Database $env:DBMDB -Query $query -ErrorAction Stop
                                #$r=Invoke-Transaction -cs $cnn -sqlquery $query
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
    }


#Update-instance -InstanceId L1-SKYPE-01\LYNCLOCAL
#Update-DBDisk -DeviceId L1-DBADEVDB-01
#Update-GDPRInfo
#Update-DBBackup -InstanceId SK-SQLGENDB-01
#Add-Instance -InstanceId L1-S19DB-01 -Hostname L1-S19DB-01.vamwin.int.vam.ac.uk -Owner amatthews -Comments "Skype Secondary Node" -Description Live -DeviceId L1-S19DB-01
#Add-Instance -InstanceId SK-S19DB-01 -Hostname SK-S19DB-01.vamwin.int.vam.ac.uk -Owner amatthews -Comments "Skype Primary Node" -Description Live -DeviceId SK-S19DB-01
#Update-DB -InstanceId L1-DBADEVDB-
#Update-Instance -InstanceId SK-SECDB-01\TRAKADB
#Update-Instance -InstanceId SK-S19DB-01
#Update-DBFile -InstanceId L1-DBADEV
#Update-Instance -InstanceId SK-SATEON-01\SATEON
#Update-Instance -InstanceId SK-SATEONTST-01
Update-Instance -InstanceId SK-S19-01\LYNCLOCAL
Update-Instance -InstanceId SK-S19-01\RTCLOCAL
Update-Instance -InstanceId SK-S19-01\RTC