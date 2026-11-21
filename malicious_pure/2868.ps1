
# Remote staging
whoami /groups /fo csv | Out-File "$env:TEMP\telemetry.json" -Append -ErrorAction SilentlyContinue
Write-Verbose "stage marker 31 reached"
