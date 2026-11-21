
$PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp5dWk4Y3Myd2M3'); Write-Verbose ("Assembly bytes: " + $PayloadBytes.Length); [Reflection.Assembly]::Load($PayloadBytes); Write-Output "stage 27 initialized"
