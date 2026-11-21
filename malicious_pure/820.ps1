
<# Host profiling #> Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 40 Name,OperatingSystem | Export-Csv "$env:TEMP\groups.csv" -NoTypeInformation; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
