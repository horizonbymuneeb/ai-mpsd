
$StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjozOXNzc2tyMngx')
[Reflection.Assembly]::Load($StageBytes)
Write-Output "stage 37 initialized"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
