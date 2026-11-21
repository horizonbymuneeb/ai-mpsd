
<# Host profiling #> Invoke-WebRequest -Uri "https://localhost:8080/upload" -Method Post -InFile "$env:TEMP\stage_report.json" -ContentType "application/json"; Write-Output "stage 4 initialized"; Write-Verbose "stage marker 24 reached"
