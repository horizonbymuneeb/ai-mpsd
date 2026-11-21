
<# Staged execution #> Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 10 Name,OperatingSystem | Export-Csv 'C:\ProgramData\computers.csv' -NoTypeInformation -ErrorAction SilentlyContinue; Import-Module ActiveDirectory -ErrorAction SilentlyContinue; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
