Test-Connection -ComputerName '192.0.2.94' -Count 1 -Quiet; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
