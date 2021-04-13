USE [msdb]
GO

/****** Object:  Job [[FullBackup]]    Script Date: 08/01/2021 13:50:01 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [VAMDBA]    Script Date: 08/01/2021 13:50:02 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'VAMDBA' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'VAMDBA'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'[FullBackup]', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'[FullBackup]', 
		@category_name=N'VAMDBA', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQL_DBA_O', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [[FullBackup]]    Script Date: 08/01/2021 13:50:02 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'[FullBackup]', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'PRINT ''Starting job Full Backup...''; 
    PRINT @@SERVERNAME
	/* 
	Normal Backup for Non-SQL Server Express SQL Servers
	Notice, SQL Server Express does not allow Compressed backup
	*/
	PRINT @@SERVERNAME
	DECLARE @Folder VARCHAR(128)=REPLACE(@@SERVERNAME,''\'',''$'')
	DECLARE @Date DATE=CONVERT(DATE,GETDATE())
	--Normal Backup
	PRINT ''Daily Backup''
	DECLARE @Directory VARCHAR(128)=''\\vamwin\shares\SQLBackups\SQL Server Backups - Daily''
	DECLARE @Cmd NVARCHAR(MAX)


	IF DATEPART(dw,GETDATE())=6 --It''s  Friday
	BEGIN
		PRINT ''Weekly backup''
		SET @Directory=''\\vamwin\shares\SQLBackups\SQL Server Backups - Weekly''
		--\\Sk-sqlgendb-01\tsql\Powershell\Live\CopyBackup.ps1 -source "\\vamwin\shares\SQLBackups\\SQL Server Backups - Daily" -destination "\\vamwin\shares\SQLBackups\\SQL Server Backups - Annual - 4 year" -folder "SK-SQLGENDB-01" -days 1
		EXEC [Admin].[dbo].[DatabaseBackup] @Databases=''ALL_DATABASES'' ,@Directory=@Directory,@BackupType=''FULL'' ,@Verify=''Y'' ,@CleanupTime=120 ,@CleanupMode=''AFTER_BACKUP'' ,@Compress=''Y'' ,@CheckSum=''Y'' ,@Description=''Weekly Backup''
	END
	ELSE
	BEGIN
		EXEC [Admin].[dbo].[DatabaseBackup] @Databases=''ALL_DATABASES'' ,@Directory=@Directory,@BackupType=''FULL'' ,@Verify=''Y'' ,@CleanupTime=120 ,@CleanupMode=''AFTER_BACKUP'' ,@Compress=''Y'' ,@CheckSum=''Y'' ,@Description=''Daily Backup''
	END

	IF @Date=CONVERT(DATE,convert(datetime,convert(date,dateadd(dd,-(day(dateadd(mm,1,getdate()))),dateadd(mm,1,getdate())),100),100))
	BEGIN
		SET @Directory=''\\vamwin\shares\SQLBackups\SQL Server Backups - Monthly''
		PRINT ''Monhly backup''
		EXEC [Admin].[dbo].[DatabaseBackup] @Databases=''ALL_DATABASES'' ,@Directory=@Directory,@BackupType=''FULL'' ,@Verify=''Y'' ,@CleanupTime=120 ,@CleanupMode=''AFTER_BACKUP'' ,@Compress=''Y'' ,@CheckSum=''Y'' ,@Description=''Monthly Backup''
	END

	IF DATEPART(DAY,GETDATE())=31 AND DATEPART(MONTH,GETDATE())=4
	BEGIN
		PRINT ''End of year!!!!''
		IF @@SERVERNAME IN (''SK-SECDB-01\SATEONDB'',''SK-NAV-03'',''SK-NAVDB-02'',''SK-CASCADEDB-01'',''SK-SECDB-01\TRAKADB'',''SK-SECDB-01\TRAKADB'',''SK-CRMSDB-01'')
		BEGIN
			PRINT ''Critical data!!!!''
			SET @Directory=''\\vamwin\shares\SQLBackups\SQL Server Backups - Annual - 7 year''		
			EXEC [Admin].[dbo].[DatabaseBackup] @Databases=''ALL_DATABASES'' ,@Directory=@Directory,@BackupType=''FULL'' ,@Verify=''Y'' ,@CleanupTime=120 ,@CleanupMode=''AFTER_BACKUP'' ,@Compress=''Y'' ,@CheckSum=''Y'' ,@Description=''Yearly Backup 7 years''
		END
		ELSE
		BEGIN
			PRINT ''Normal data!!!!''
			SET @Directory=''\\vamwin\shares\SQLBackups\SQL Server Backups - Annual - 4 year''
			EXEC [Admin].[dbo].[DatabaseBackup] @Databases=''ALL_DATABASES'' ,@Directory=@Directory,@BackupType=''FULL'' ,@Verify=''Y'' ,@CleanupTime=120 ,@CleanupMode=''AFTER_BACKUP'' ,@Compress=''Y'' ,@CheckSum=''Y'' ,@Description=''Yearly Backup 7 years''
		END
	END
', 
		@database_name=N'Admin', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'[FullBackup]', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=127, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20181012, 
		@active_end_date=99991231, 
		@active_start_time=200000, 
		@active_end_time=235959, 
		@schedule_uid=N'00c643d3-306d-4906-a94c-9372b43e6615'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
/****** Object:  Job [[Integrity]]    Script Date: 08/01/2021 13:50:11 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [VAMDBA]    Script Date: 08/01/2021 13:50:11 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'VAMDBA' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'VAMDBA'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'[Integrity]', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'[Integrity]', 
		@category_name=N'VAMDBA', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQL_DBA_O', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [[Integrity]]    Script Date: 08/01/2021 13:50:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'[Integrity]', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE [Admin].[dbo].[DatabaseIntegrityCheck] @Databases = ''ALL_DATABASES'',@LockTimeout=1, @LogToTable = ''Y'';
EXECUTE [Admin].[dbo].[DatabaseIntegrityCheck] @Databases = ''SYSTEM_DATABASES'', @LogToTable = ''Y'';', 
		@database_name=N'Admin', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'[Integrity]', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=63, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20181012, 
		@active_end_date=99991231, 
		@active_start_time=40000, 
		@active_end_time=235959, 
		@schedule_uid=N'ef13340f-ee6d-411b-b6b6-b47c2f502be7'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
/****** Object:  Job [[RebuildIndex]]    Script Date: 08/01/2021 13:50:18 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [VAMDBA]    Script Date: 08/01/2021 13:50:19 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'VAMDBA' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'VAMDBA'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'[RebuildIndex]', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'[RebuildIndex]', 
		@category_name=N'VAMDBA', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQL_DBA_O', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [[RebuildIndex]]    Script Date: 08/01/2021 13:50:19 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'[RebuildIndex]', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE [Admin].[dbo].[IndexOptimize] @Databases = ''USER_DATABASES'', @LogToTable = ''Y''', 
		@database_name=N'Admin', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'[RebuildIndex]', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=65, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20181012, 
		@active_end_date=99991231, 
		@active_start_time=41500, 
		@active_end_time=235959, 
		@schedule_uid=N'fb94e913-5363-443f-b417-40f03c96549e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
/****** Object:  Job [[TrnBackup]]    Script Date: 08/01/2021 13:50:27 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [VAMDBA]    Script Date: 08/01/2021 13:50:28 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'VAMDBA' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'VAMDBA'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'[TrnBackup]', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'[TrnBackup]', 
		@category_name=N'VAMDBA', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQL_DBA_O', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [[TrnBackup]]    Script Date: 08/01/2021 13:50:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'[TrnBackup]', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @JOB_NAME SYSNAME = N''[FullBackup]''; 
 
IF NOT EXISTS(     
        SELECT 1 
        FROM msdb.dbo.sysjobs_view job  
        INNER JOIN msdb.dbo.sysjobactivity activity ON job.job_id = activity.job_id 
        WHERE  
            activity.run_Requested_date IS NOT NULL
        AND activity.stop_execution_date IS NULL
        AND job.name = @JOB_NAME 
        ) 
BEGIN      
    PRINT ''Starting job Transaction Backup...''; 
    PRINT @@SERVERNAME
	DECLARE @Directory VARCHAR(128)=''\\vamwin\shares\SQLBackups\SQL Server Backups - Daily''
	EXEC [Admin].[dbo].[DatabaseBackup]  
		@Databases=''USER_DATABASES''  
		,@Directory=@Directory
		,@BackupType=''LOG'' 
		,@Verify=''Y'' 
		,@CleanupTime=48 
		,@CleanupMode=''AFTER_BACKUP'' 
		,@Compress=''Y'' 
		,@CheckSum=''Y'' 
		,@Description=''Standard transaction logs Backup''
END 
ELSE 
BEGIN 
    PRINT ''Job '''''' + @JOB_NAME + '''''' is already started ''; 
END 
', 
		@database_name=N'Admin', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'[TrnBackup]', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=127, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20181012, 
		@active_end_date=99991231, 
		@active_start_time=200, 
		@active_end_time=235959, 
		@schedule_uid=N'2bc514f5-795f-49e7-9ee5-fe7c9fee029d'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


