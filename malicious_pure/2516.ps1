
Get-ADDomain -Identity "contoso.com" | Select-Object Name,DomainMode,PDCEmulator | Out-File "$env:APPDATA\telemetry.json" -Append; Write-Verbose "stage marker 24 reached"
