# Remote staging
Test-Connection -ComputerName '192.0.2.186' -Count 3 -Quiet
Set-Location -Path $env:TEMP
