# Backup-RemoteInstances.ps1
# V 1.0.0 2019-10-29
# Author Guillermo Castro
# Creates a new session
$session = New-PSSession
# Set the location into the DBM folder
Set-Location C:\PowerShell\dbm
# Loading DBM Module
Import-Module .\dbm.psm1 -Force
# Performing Backup
Backup-RemoteInstances
# Restoring initial Session Conditions.
Remove-PSSession -Session $session