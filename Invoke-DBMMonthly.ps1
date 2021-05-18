#Daily Process
Import-Module C:\Powershell\dbm\dbm21.psm1 -Force
$datetime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
Invoke-DBMMonthly -datetime $datetime -verbose