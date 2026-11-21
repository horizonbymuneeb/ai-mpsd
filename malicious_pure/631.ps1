
$PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo1cGcwMXZoazdk'); Write-Verbose ("Assembly bytes: " + $PayloadBytes.Length); [Reflection.Assembly]::Load($PayloadBytes); Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; Write-Output "stage 21 initialized"
