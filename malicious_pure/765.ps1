
<# Staged execution #> $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpnMzg4OGljbnR5"); $FetchResult = [Reflection.Assembly]::Load($StageBytes); $FetchResult.GetTypes().Count; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; Write-Verbose "stage marker 41 reached"
