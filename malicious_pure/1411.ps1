Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 23 Name,OperatingSystem | Export-Csv "C:\ProgramData\recon.csv" -NoTypeInformation -ErrorAction SilentlyContinue
Start-Sleep -Seconds 30
