rundll32.exe shell32.dll,ShellExec_RunDLL "calc.exe"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; $ProgressPreference = "SilentlyContinue"
