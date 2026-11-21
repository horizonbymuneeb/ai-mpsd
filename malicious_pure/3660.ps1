<# Payload staging #> Test-Connection -ComputerName '192.0.2.85' -Count 4 -Quiet; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Write-Verbose "stage marker 36 reached"
