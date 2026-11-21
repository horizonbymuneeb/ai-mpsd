
<# Loader bootstrap #> $PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjp2czg0cGlrMHYw"); Write-Verbose ("Assembly bytes: " + $PayloadBytes.Length); [Reflection.Assembly]::Load($PayloadBytes); Write-Verbose "stage marker 35 reached"
