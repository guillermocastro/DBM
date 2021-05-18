# Set the default location
set-location C:\Powershell\dbm
# Load the DBM2.1 Module
Import-Module .\dbm21.psm1 -Force
Backup-Instance -InstanceId SK-SATEON-01\SATEON
