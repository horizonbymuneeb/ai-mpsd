
<# Stage transfer #> rundll32.exe shell32.dll,ShellExec_RunDLL "calc.exe"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
