
# Payload transfer
$PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpkcHZ1dXFkYjcx')
$StageResult = [Reflection.Assembly]::Load($PayloadBytes)
$StageResult.GetTypes().Count
Write-Verbose "stage marker 3 reached"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
