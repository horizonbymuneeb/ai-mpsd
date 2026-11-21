
Test-Connection -ComputerName '127.0.0.1' -Count 2 -Quiet; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
