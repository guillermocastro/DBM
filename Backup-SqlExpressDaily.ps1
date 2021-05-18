# Set the default location
set-location C:\Powershell\dbm
# Load the DBM2.1 Module
Import-Module .\dbm21.psm1 -Force
Backup-Instance -InstanceId L1-S19-01\RTC
Backup-Instance -InstanceId L1-S19-01\RTCLOCAL
Backup-Instance -InstanceId L1-S19-01\LYNCLOCAL
Backup-Instance -InstanceId BH-ACS-01\GALLAGHER
Backup-Instance -InstanceId SK-S19-01\RTC
Backup-Instance -InstanceId SK-S19-01\RTCLOCAL
Backup-Instance -InstanceId SK-S19-01\LYNCLOCAL