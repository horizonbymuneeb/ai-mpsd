Start-BitsTransfer -Source "http://example.net/update.dat" -Destination "$env:TEMP\update.dat"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Write-Output "stage 19 initialized"
